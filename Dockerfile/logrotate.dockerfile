FROM alpine:latest
LABEL autor="Joao Costa"

RUN apk update
RUN apk upgrade
RUN apk add logrotate gzip

COPY --chown=root:root --chmod=0644 ./conf/logrotate.d/nginx /etc/logrotate.d/nginx
