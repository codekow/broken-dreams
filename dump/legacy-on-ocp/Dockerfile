FROM docker.io/qemux/qemu

COPY src/ /run/

# fix running as root
RUN chmod 2775 /run /etc/nginx/sites-enabled/ /etc/nginx/ /var/lib/nginx/ /var/log/nginx/ && \
    chown root:root /run /var/log/nginx/ && \
    rm /var/log/nginx/*

USER 1001

EXPOSE 2222
