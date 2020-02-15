# Running Divinium Officium

Goal for this page is to document all the different components that are used to run Divinium Officium (DO) team to deploy new servers for production deployment of [DivinumOfficium](https://www.divinumofficium.com/).  The codebase for this website is [DivinumOfficium/divinum-officium](https://github.com/DivinumOfficium/divinum-officium).

## Overall
The flow for getting code commit updates running onto the actual 

=> **Ben** - I'm kinda guessing here - not sure what is running where :)

1. Code committed to [DivinumOfficium/divinum-officium](https://github.com/DivinumOfficium/divinum-officium)
2. Auto update process in Github builds a new docker image of DiviniumOfficium, and updates  docker hub
3.  Magic happens?  :)

Initial tests showed that the automated commit to deploy pipeline was under 10 minutes.

## Components

### Divinium Officium
[Divinium Officium's technical information](https://www.divinumofficium.com/www/horas/Help/technical.html) defines how the data files are defined, how to run the program and nuances of file contents and exceptions.  The [download files](https://www.divinumofficium.com/www/horas/Help/download.html) page defines the different ways the DO files can be used, inclduing running DO in a [Docker container](https://www.docker.com/why-docker).

### Ansible
[Ansible](https://www.ansible.com/overview/it-automation) is used to define, create and manages the servers which run DO.  The Ansible [playbook.yml](https://github.com/DivinumOfficium/ansible-deployment/blob/master/playbook.yml) file is the definition file that Ansible runs to set up a new server running Divinium Officium.  Some highlights:

* Using canonical repo for [Ubuntu](https://help.ubuntu.com/community/Repositories/Ubuntu)
* Image configured to use Ubuntu's "unattended-upgrades" package, which will apply the latest stable packages from Ubuntu
* If a reboot is needed for security patches, Ubuntu will reboot in the middle of the night

### Docker

DO is designed to run in Docker, so the Ansible playbook installs [Docker Swarm](https://docs.docker.com/engine/swarm) onto the DO server. In this way, load is managed by serving up new Docker DO instances as user demand comes in.

### Continuous Integration (CI)

=> **Ben** - is there a CI tool running this?  I assume yes - wasn't sure what

### Hosting
Divinium Officium is hosted on Google Cloud Platform (GCP).  Please contact <canon.missae@gmail.com> for any issues or questions.

### Monitoring
=> **Ben** -is there any monitoring?

