## Introduction
This Dockerfile will build a container image with Postfix, Dovecot and OpenDKIM for virtual mailhosting. Dovecot also has support for sieve/managesieve built into this build. The image is based on CentOS 7. It also includes rsyslog for logging.

## Repositories

### GitHub
The source files for this project are available on GitHub: [https://github.com/TheKatastrophe/vmail-postfix-dovecot-opendkim](https://github.com/TheKatastrophe/vmail-postfix-dovecot-opendkim)

### Docker Hub
The Docker Hub page for this project can be found [here](https://hub.docker.com/r/katastrophe/vmail-postfix-dovecot-opendkim/).

## Usage

### Pulling from Docker Hub
To pull this Dockerfile from Docker Hub:

	docker pull katastrophe/vmail-postfix-dovecot-opendkim

### Building from source
You can build this container from source with:

	git clone https://github.com/TheKatastrophe/vmail-postfix-dovecot-opendkim.git
	docker build -t katastrophe/vmail-postfix-dovecot-opendkim:latest .

### Running
Run the container with minimal configuration and options:

	docker run --name <container_name> -p 25:25 -p 465:465 -p 587:587 -p 110:110 -p 995:995 -p 143:143 -p 993:993 -d -h <container_hostname> -e "MAIL_HOSTNAME=<short_hostname>" -e "MAIL_HOSTNAME_FQDN=<fqdn_hostname>" -e "POSTMASTER_ADDRESS=<postmaster_email_address>" -it katastrophe/vmail-postfix-dovecot-opendkim /start.sh

This will run the container. You can then use the scripts `add_mail_domain`, `add_mail_user` and `add_mail_alias` scripts to setup the mail server. Self-signed SSL certs will be generated, but you can replace these - these live at /etc/ssl/mailcerts.

Please note that it's very important to set the environment variables, as these are used for configuring the various services:

- `MAIL_HOSTNAME` should be the hostname of the mail server, without domain. If your mail server is `mailserver.domain.com`, this would be `mailserver`. This effectively gets used for the `myhostname` Postfix parameter.
- `MAIL_HOSTNAME_FQDN` should be the fully-qualified hostname for the mail server. In the above example, this would be `mailserver.domain.com`. This gets used for the `mydomain` Postfix parameter, added to the `TrustedHosts` file for OpenDKIM and used as the subject for the self-signed SSL certificate generated.
- `POSTMASTER_ADDRESS` should be the address of your postmaster email account. This will be used for Dovecot's `postmaster_address' parameter.

### Other options

#### Linking volumes

Syntax: `-v /host/path:/container/path`

You can use Docker to link a path within the container to a path on the host. For example, to expose the mail storage on the Docker host at `/opt/mail`, you could use:

	docker run --name <container_name> -d -h <container_hostname> -v /opt/mail:/var/vmail [...] -it katastrophe/vmail-postfix-dovecot-opendkim /start.sh

Useful volumes to link:
- `/var/vmail`: All mailboxes are stored here under `<domain>/<username>`.
- `/etc/vmail`: Configuration of domains, users, aliases and passwords are stored in this folder.
- `/etc/ssl/mailcerts`: SSL certificates for the mail server are stored here, by default self-signed certs are generated on deploy.

#### Useful scripts

Three scripts are available for adding users, domains and aliases:

- `/usr/bin/add_mail_domain <domain>`: Add a domain that the server will accept mail for. This will also create the necessary folder structure in `/var/vmail`.
- `/usr/bin/add_mail_user <email address>`: Add a user that the server will accept mail for. This will prompt for a password to be used for the new user.
- `/usr/bin/add_mail_alias <alias email address> <target email address>`: This will add a mail alias of `<alias email address>` for the `<target email address>`.
- `/usr/bin/change_mail_password <email address>`: Change an existing user's password. This will prompt for a new password.
- `/usr/bin/get_dkim_record`: This will return a DNS record for the generated DKIM keys for use in your zonefile or DNS provider.

These scripts will make all necessary changes and reload all necessary services. They can be run from the docker host with, using `add_mail_domain` as an example:

	docker exec -ti <container_name> add_mail_domain example.com