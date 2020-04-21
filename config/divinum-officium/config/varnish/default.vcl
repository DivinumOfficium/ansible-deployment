vcl 4.0;

import std;
import directors;

backend server1 {
  .host = "app";
  .port = "8080";
  .max_connections = 50;

    .probe = {
      #.url = "/"; # short easy way (GET /)
      # We prefer to only do a HEAD /
      .request =
        "HEAD / HTTP/1.1"
        "Host: localhost"
        "Connection: close"
        "User-Agent: Varnish Health Probe";

      .interval  = 5s; # check the health of each backend every 5 seconds
      .timeout   = 3s; # timing out after 1 second.
      .window    = 5;  # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
      .threshold = 3;
    }

    .first_byte_timeout     = 300s;   # How long to wait before we receive a first byte from our backend?
    .connect_timeout        = 5s;     # How long to wait for a backend connection?
    .between_bytes_timeout  = 2s;     # How long to wait between bytes received from our backend?

}

# Default TTL for cache items
sub vcl_backend_response {
    set beresp.ttl = 2h;
}


sub vcl_recv {
    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
      return (pass);
    }
}

sub vcl_recv {
    # Strip hash, server doesn't need it.
    if (req.url ~ "\#") {
      set req.url = regsub(req.url, "\#.*$", "");
    }
}


sub vcl_recv {
    # Are there cookies left with only spaces or that are empty?
    if (req.http.cookie ~ "^\s*$") {
      unset req.http.cookie;
    }

    if (req.http.Cache-Control ~ "(?i)no-cache") {
    #if (req.http.Cache-Control ~ "(?i)no-cache" && client.ip ~ editors) { # create the acl editors if you want to restrict the Ctrl-F5
    # http://varnish.projects.linpro.no/wiki/VCLExampleEnableForceRefresh
    # Ignore requests via proxy caches and badly behaved crawlers
    # like msnbot that send no-cache with every request.
      if (! (req.http.Via || req.http.User-Agent ~ "(?i)bot" || req.http.X-Purge)) {
        #set req.hash_always_miss = true; # Doesn't seems to refresh the object in the cache
        return(purge); # Couple this with restart in vcl_purge and X-Purge header to avoid loops
      }
    }
}

sub vcl_recv {
    # Send Surrogate-Capability headers to announce ESI support to backend
    set req.http.Surrogate-Capability = "key=ESI/1.0";

    if (req.http.Authorization) {
      # Not cacheable by default
      return (pass);
    }
}

sub vcl_hash {
    # hash cookies for requests that have them
    if (req.http.Cookie) {
      hash_data(req.http.Cookie);
    }
}


sub vcl_deliver {
    if (obj.hits > 0) { # Add debug header to see if it's a HIT/MISS and the number of hits, disable when not needed
      set resp.http.X-Cache = "HIT";
    } else {
      set resp.http.X-Cache = "MISS";
    }
    return (deliver);
}

# Normalize header
#sub vcl_recv {
    # Normalize the header, remove the port (in case you're testing this on various TCP ports)
#    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");
#}

# Remove proxy
#sub vcl_recv {
    # Remove the proxy header (see https://httpoxy.org/#mitigate-varnish)
#    unset req.http.proxy;
#}

#sub vcl_recv {
    # Normalize the query arguments
#    set req.url = std.querysort(req.url);
#}


# Hash cookies for caching
sub vcl_hash {
    # hash cookies for requests that have them
    if (req.http.Cookie) {
      hash_data(req.http.Cookie);
    }
}

# vcl_hit - find better example here
# https://www.varnish-software.com/wiki/content/tutorials/varnish/sample_vclTemplate.html

# Pass real IP to backend


# Assets
#	set beresp.http.Cache-Control = "max-age=7200s"; # Cache 2 hours in browser (UP THIS LATER)
#	set beresp.ttl = 28800s; # Cache 8 hrs in varnish	


# content
#	set beresp.ttl = 1800s; # Cache 30 minutes in varnish



# Improve logging of hit/miss

