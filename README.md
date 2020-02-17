# Running Divinium Officium

Goal for this page is to document all the different components that are used to run Divinium Officium (DO), to deploy new servers for production deployment of [DivinumOfficium](https://www.divinumofficium.com/).  The codebase for this website is [DivinumOfficium/divinum-officium](https://github.com/DivinumOfficium/divinum-officium).

## Overall
The flow for getting code commit updates running onto the actual 

1. Code committed to [DivinumOfficium/divinum-officium](https://github.com/DivinumOfficium/divinum-officium)
2. Github sends webhook to [Docker Hub](https://hub.docker.com/r/divinumofficiumweb/divinumofficium), which builds and stores the image
2. Webserver is configured, with `ouroboros` running in a container, to check every few minutes for a new image from Docker Hub. When it finds a new image, it pulls and runs the new image.

Initial tests showed that the automated commit to deploy pipeline was under 10 minutes.

## Components

### Divinium Officium

[Divinium Officium's technical information](https://www.divinumofficium.com/www/horas/Help/technical.html) defines how the data files are defined, how to run the program and nuances of file contents and exceptions.  The [download files](https://www.divinumofficium.com/www/horas/Help/download.html) page defines the different ways the DO files can be used, including running DO in a [Docker container](https://www.docker.com/why-docker).

### Ansible

[Ansible](https://www.ansible.com/overview/it-automation) is used to define, create and manages the servers which run DO.

The Ansible [playbook.yml](https://github.com/DivinumOfficium/ansible-deployment/blob/master/playbook.yml) file is the definition file that Ansible runs to set up a new server running Divinium Officium. Some highlights:

* Using canonical repo for [Ubuntu](https://help.ubuntu.com/community/Repositories/Ubuntu)
* Image configured to use Ubuntu's "unattended-upgrades" package, which will apply the latest stable packages from Ubuntu
* If a reboot is needed for security patches, Ubuntu will reboot in the middle of the night

Note that Ansible operates on servers over your existing SSH credentials, so Ansible should be installed on your local workstation, and then use it to SSH into the remote instances and configure them. For more information on this, consult the [Ansible documentation](https://spin.atomicobject.com/2015/09/21/ansible-configuration-management-laptop/).

### Docker

The application is built by [Docker Hub](https://hub.docker.com/r/divinumofficiumweb/divinumofficium), and the build image is stored there, publicly accessible for anyone to pull. The docker hub account is connected to the github repo, to rebuild in real time on new commits. Additionally, PR branches are tested against the build before merging.

### Hosting

Divinium Officium is hosted on Google Cloud Platform (GCP).  Please contact <canon.missae@gmail.com> for any issues or questions.

### Monitoring

There is no monitoring yet, but this is a desired thing we would like to add.

