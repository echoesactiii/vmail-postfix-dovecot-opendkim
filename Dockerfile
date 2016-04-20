FROM centos:7
MAINTAINER Kat Andry (kat@mxandry.net)

ENV container docker

# Install supervisord
RUN \
  yum update -y && \
  yum install -y epel-release && \
  yum install -y iproute python-setuptools hostname inotify-tools yum-utils which && \
  yum clean all && \
  easy_install supervisor

# Install packages
RUN yum -y install openssl postfix dovecot dovecot-pigeonhole opendkim opendkim-tools 

# Make some folders & users & stuff
RUN useradd vmail -d /var/vmail -M -r -s /usr/sbin/nologin -U && \
mkdir -m 0755 /etc/ssl/mailcerts && \
mkdir -m 0755 /etc/vmail && \
mkdir -m 0751 /var/vmail && \
chown vmail:vmail /var/vmail

# Postfix config
RUN rm /etc/postfix/main.cf /etc/postfix/master.cf
ADD conf/main.cf /etc/postfix/main.cf
ADD conf/master.cf /etc/postfix/master.cf
RUN touch /etc/vmail/aliases /etc/vmail/domains /etc/vmail/mailboxes /etc/vmail/passwd

# Dovecot config
RUN rm /etc/dovecot/dovecot.conf /etc/dovecot/conf.d/*
ADD conf/dovecot.conf /etc/dovecot/dovecot.conf
ADD conf/15-lda.conf /etc/dovecot/conf.d/15-lda.conf
ADD conf/20-managesieve.conf /etc/dovecot/conf.d/20-managesieve.conf
ADD conf/90-sieve-extprograms.conf /etc/dovecot/conf.d/90-sieve-extprograms.conf
ADD conf/90-sieve.conf /etc/dovecot/conf.d/90-sieve.conf

# OpenDKIM config
ADD conf/opendkim.conf /etc/opendkim.conf
ADD conf/TrustedHosts /etc/opendkim/TrustedHosts
RUN opendkim-default-keygen

# Supervisor Config
ADD conf/supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Setup Volume
VOLUME ["/var/vmail"]
VOLUME ["/etc/vmail"]
VOLUME ["/etc/ssl/mailcerts"]

# Expose Ports
EXPOSE 465
EXPOSE 25
EXPOSE 587
EXPOSE 993
EXPOSE 143
EXPOSE 110
EXPOSE 995
EXPOSE 4190

CMD ["/bin/bash", "/start.sh"]