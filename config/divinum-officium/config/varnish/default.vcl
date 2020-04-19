vcl 4.0;

# Allowable purge request sources
acl purge {
    # ACL we'll use later to allow purges
    "localhost";
    "127.0.0.1";
    "::1";
}


backend default {
  .host = "app";
  .port = "8080";
  .max_connections = "50";

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
}

sub vcl_recv {
    # Normalize the header, remove the port (in case you're testing this on various TCP ports)
    set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");
}


sub vcl_recv {
    # Remove the proxy header (see https://httpoxy.org/#mitigate-varnish)
    unset req.http.proxy;
}


sub vcl_recv {
    # Normalize the query arguments
    set req.url = std.querysort(req.url);
}


# Allow purging
sub vcl_recv {
    # Allow purging
    if (req.method == "PURGE") {
      if (!client.ip ~ purge) { # purge is the ACL defined at the begining
        # Not from an allowed IP? Then die with an error.
        return (synth(405, "This IP is not allowed to send PURGE requests."));
      }
      # If you got this stage (and didn't error out above), purge the cached result
      return (purge);
    }
}



# Hash cookies for caching
sub vcl_hash {
    # hash cookies for requests that have them
    if (req.http.Cookie) {
      hash_data(req.http.Cookie);
    }
}


# Serve queued requests nicely
sub vcl_hit {
    # https://www.varnish-cache.org/docs/trunk/users-guide/vcl-grace.html
    # When several clients are requesting the same page Varnish will send one request to
    # the backend and place the others on hold while fetching one copy from the backend.
    # In some products this is called request coalescing and Varnish does this automatically.
    # If you are serving thousands of hits per second the queue of waiting requests can get huge.
    # There are two potential problems - one is a thundering herd problem - suddenly releasing a thousand
    # threads to serve content might send the load sky high. Secondly - nobody likes to wait. To deal
    # with this we can instruct Varnish to keep the objects in cache beyond their TTL and to serve
    # the waiting requests somewhat stale content.

    # We have no fresh fish. Lets look at the stale ones.
    if (std.healthy(req.backend_hint)) {
      # Backend is healthy. Limit age to 10s.
      if (obj.ttl + 10s > 0s) {
        #set req.http.grace = "normal(limited)";
        return (deliver);
      } else {
        # No candidate for grace. Fetch a fresh object.
        return(fetch);
      }
    } else {
      # backend is sick - use full grace
        if (obj.ttl + obj.grace > 0s) {
        #set req.http.grace = "full";
        return (deliver);
      } else {
        # no graced object.
        return (fetch);
      }
    }

    # fetch & deliver once we get the result
    return (fetch); # Dead code, keep as a safeguard
}


# Pass real IP to backend
sub vcl_recv {
    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) {
           set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
       } else {
        set req.http.X-Forwarded-For = client.ip;
       }
    }
}



# Assets
#	set beresp.http.Cache-Control = "max-age=7200s"; # Cache 2 hours in browser (UP THIS LATER)
#	set beresp.ttl = 28800s; # Cache 8 hrs in varnish	


# content
#	set beresp.ttl = 1800s; # Cache 30 minutes in varnish

