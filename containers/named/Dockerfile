FROM registry.fedoraproject.org/fedora:36

LABEL org.opencontainers.image.title='named - DNS server'
LABEL org.opencontainers.image.description='A feature rich DNS server.'
LABEL org.opencontainers.image.authors='Cory Latschkowski <cory@happykow.com>'
LABEL org.opencontainers.image.documentation='https://github.com/codekow/containers.git'
LABEL org.opencontainers.image.source='https://github.com/codekow/containers.git'
LABEL org.opencontainers.image.licenses='MIT'

RUN dnf -y \
    --setopt=tsflags=nodocs \
    install bind bind-utils \
    && dnf clean all

COPY config/named.conf /config/named.conf
COPY config/ddns-key.tsig /config/ddns-key.tsig
COPY config/named.empty /var/named/data/db.example.com

RUN chmod 775 /var/named \
    && chown -R 1001:0 \
    /var/named \
    /etc/named* \
    /var/run/named

VOLUME /var/named
WORKDIR /var/named

USER 1001
EXPOSE 5353/udp 5353/tcp

ENTRYPOINT /usr/sbin/named -g -c /config/named.conf
