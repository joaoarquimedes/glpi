ARG ARCH=${ARCH}
ARG PHP_VERSION=${PHP_VERSION}
FROM --platform=${ARCH} php:${PHP_VERSION}
LABEL maintainer="Joao Costa"

# Update
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt upgrade -y

# #################################################
# # --> PHP-FPM
# #################################################
RUN apt-get install -y --no-install-recommends \
        gettext \
        libc-client-dev \
        libbz2-dev \
        libgettextpo-dev \
        libicu-dev \
        libkrb5-dev \
        libldap2-dev \
        libonig-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        perl \
        postgresql-server-dev-all \
        unixodbc-dev \
        zip

# Algumas dependências exigem configuração antes da compilação
RUN docker-php-ext-configure intl
RUN docker-php-ext-configure gettext
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl
RUN docker-php-ext-configure ldap

# Instala as extensões do PHP
RUN docker-php-ext-install \
    bcmath \
    bz2 \
    calendar \
    ctype \
    dom \
    exif \
    fileinfo \
    gd \
    gettext \
    imap \
    intl \
    ldap \
    mbstring \
    mysqli \
    opcache \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    session \
    shmop \
    simplexml \
    soap \
    sysvmsg \
    sysvsem \
    sysvshm \
    xml \
    zip

# PHP-FPM (daemon)
COPY --chown=root:root --chmod=664 conf/www.conf /usr/local/etc/php-fpm.d/www.conf
RUN rm -rf /usr/local/etc/php-fpm.d/zz-docker.conf
# PHP ini
COPY --chown=root:root --chmod=664 conf/custom-php.ini /usr/local/etc/php/conf.d/custom-php.ini

#################################################
# --> NGINX
#################################################
RUN apt-get install -y --no-install-recommends \
    bash \
    curl \
    openssl \
    ca-certificates \
    libpcre3 \
    zlib1g
RUN apt-get install -y --no-install-recommends \
    build-essential \
    linux-headers-$(uname -r) || true && \
    apt-get install -y --no-install-recommends \
    libpcre3-dev \
    zlib1g-dev

WORKDIR /usr/src/
ARG NGINX_VERSION=${NGINX_VERSION}
RUN curl -L "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx-${NGINX_VERSION}.tar.gz
RUN tar -zxf nginx-${NGINX_VERSION}.tar.gz
WORKDIR /usr/src/nginx-${NGINX_VERSION}/
RUN mkdir -p /var/cache/nginx
RUN ./configure --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=www-data \
    --group=www-data \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_v2_module

RUN make && make install
RUN cd ../ && rm -rf nginx-${NGINX_VERSION}.tar.gz nginx-${NGINX_VERSION}/

# Nginx
COPY --chown=root:root --chmod=664 ./conf/nginx.conf /etc/nginx/nginx.conf



#################################################
# --> Certificado Digital
#################################################
RUN apt install -y openssl
RUN mkdir -p /etc/nginx/ssl/certs \
    && mkdir -p /etc/nginx/ssl/crl \
    && mkdir -p /etc/nginx/ssl/newcerts \
    && touch /etc/nginx/ssl/index.txt \
    && date | md5sum | sed 's/  -//' > /etc/nginx/ssl/serial \
    && echo 1000 > /etc/nginx/ssl/crlnumber

COPY --chown=root:root --chmod=664 ./conf/openssl.cnf /etc/nginx/ssl/openssl.cnf

ARG CERT_DOMAINNAME=${CERT_DOMAINNAME}
ARG CERT_COUNTRYNAME=${CERT_COUNTRYNAME}
ARG CERT_STATEORPROVINCE=${CERT_STATEORPROVINCE}
ARG CERT_LOCALITY=${CERT_LOCALITY}
ARG CERT_ORGANIZATIONNAME=${CERT_ORGANIZATIONNAME}
ARG CERT_COMMONNAME=${CERT_COMMONNAME}
ARG CERT_MAILADDRESS=${CERT_MAILADDRESS}

RUN sed -i "s/CERT_DOMAINNAME/${CERT_DOMAINNAME}/g" /etc/nginx/ssl/openssl.cnf \
    && sed -i "s/CERT_COUNTRYNAME/${CERT_COUNTRYNAME}/g" /etc/nginx/ssl/openssl.cnf \
    && sed -i "s/CERT_STATEORPROVINCE/${CERT_STATEORPROVINCE}/g" /etc/nginx/ssl/openssl.cnf \
    && sed -i "s/CERT_LOCALITY/${CERT_LOCALITY}/g" /etc/nginx/ssl/openssl.cnf \
    && sed -i "s/CERT_ORGANIZATIONNAME/${CERT_ORGANIZATIONNAME}/g" /etc/nginx/ssl/openssl.cnf \
    && sed -i "s/CERT_COMMONNAME/${CERT_COMMONNAME}/g" /etc/nginx/ssl/openssl.cnf \
    && sed -i "s/CERT_MAILADDRESS/${CERT_MAILADDRESS}/g" /etc/nginx/ssl/openssl.cnf

# --> Gerando certificados digitais
# Geração da CA
RUN openssl genrsa -out /etc/nginx/ssl/ca.key 4096
RUN openssl req -x509 -new -nodes -key /etc/nginx/ssl/ca.key -sha256 -days 1095 -out /etc/nginx/ssl/ca.crt -subj "/CN=InternalCA"
# Geração do certificado do servidor assinado pela CA
RUN openssl genrsa -out /etc/nginx/ssl/cert.key 2048
RUN openssl req -new -key /etc/nginx/ssl/cert.key -out /etc/nginx/ssl/cert.csr -config /etc/nginx/ssl/openssl.cnf
RUN openssl ca -batch -config /etc/nginx/ssl/openssl.cnf -extensions v3_req -days 1095 -notext -md sha256 -in /etc/nginx/ssl/cert.csr -out /etc/nginx/ssl/cert.pem
# Geração da CRL
RUN openssl ca -gencrl -config /etc/nginx/ssl/openssl.cnf -out /etc/nginx/ssl/crl/crl.pem
# Geração do DHParam
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
# Gerar fullchain (certificado + CA)
RUN cat /etc/nginx/ssl/cert.pem /etc/nginx/ssl/ca.crt > /etc/nginx/ssl/fullchain.pem
RUN chown -R www-data: /etc/nginx/ssl



#################################################
# --> SOURCE GLPI
#################################################
# NON CACHE
# ARG CACHEBUST=1
# Source GLPI
ARG GLPI_DIR=${GLPI_DIR}
RUN apt install -y rsync wget
ARG GLPI_VERSION=${GLPI_VERSION}
WORKDIR /usr/src/
RUN wget https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz
RUN tar -zxf glpi-${GLPI_VERSION}.tgz
RUN rsync -avzogH glpi/ ${GLPI_DIR}/
RUN rm -rf glpi-${GLPI_VERSION}.tgz
RUN chown -R root:www-data ${GLPI_DIR}/
# Permissions all
RUN find ${GLPI_DIR}/ -type f -exec chmod 644 {} \;
RUN find ${GLPI_DIR}/ -type d -exec chmod 755 {} \;
# Permissions files
RUN chown -R www-data: ${GLPI_DIR}/config
RUN chown -R www-data: ${GLPI_DIR}/files
# Remove install
RUN rm ${GLPI_DIR}/install/install.php


#################################################
# --> PLUGIN
#################################################
WORKDIR ${GLPI_DIR}/plugins/
RUN apt install -y git
# OCS INVENTORY NG
ARG GLPI_PLUGIN_OSINVENTORYNG
RUN git clone --branch ${GLPI_PLUGIN_OSINVENTORYNG} --depth 1 --single-branch https://github.com/pluginsGLPI/ocsinventoryng.git
# FROM CREATOR
ARG GLPI_PLUGIN_FORMCREATOR
RUN git clone --branch ${GLPI_PLUGIN_FORMCREATOR} --depth 1 --single-branch https://github.com/verdanatech/formcreator.git
# GENERIC PROJECT
ARG GLPI_PLUGIN_GENERICOBJECT
RUN git clone --branch ${GLPI_PLUGIN_GENERICOBJECT} --depth 1 --single-branch https://github.com/verdanatech/genericobject.git
# FIELDS
ARG GLPI_PLUGIN_FIELDS
RUN git clone --branch ${GLPI_PLUGIN_FIELDS} --depth 1 --single-branch https://github.com/verdanatech/fields.git
# BEHAVIORS
ARG GLPI_PLUGIN_BEHAVIORS
RUN git clone --branch ${GLPI_PLUGIN_BEHAVIORS} --depth 1 --single-branch https://github.com/verdanatech/behaviors.git
# NEWS
ARG GLPI_PLUGIN_NEWS
RUN git clone --branch ${GLPI_PLUGIN_NEWS} --depth 1 --single-branch https://github.com/verdanatech/news.git
# TAG
ARG GLPI_PLUGIN_TAG
RUN git clone --branch ${GLPI_PLUGIN_TAG} --depth 1 --single-branch https://github.com/verdanatech/tag.git
# OAUTH IMAP
ARG GLPI_PLUGIN_OAUTHIMAP
RUN git clone --branch ${GLPI_PLUGIN_OAUTHIMAP} --depth 1 --single-branch https://github.com/verdanatech/oauthimap.git
# GLPI INVENTORY
ARG GLPI_PLUGIN_GLPIINVENTORY
RUN git clone --branch ${GLPI_PLUGIN_GLPIINVENTORY} --depth 1 --single-branch https://github.com/verdanatech/glpiinventory.git
# DATA INJECTION
ARG GLPI_PLUGIN_DATAINJECTION
RUN git clone --branch ${GLPI_PLUGIN_DATAINJECTION} --depth 1 --single-branch https://github.com/verdanatech/datainjection.git

RUN chown -R root:www-data .
RUN find . -type f -exec chmod 644 {} \;
RUN find . -type d -exec chmod 755 {} \;
#################################################


#################################################
# --> Clear
#################################################
RUN apt-get purge -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

VOLUME [ "/home/www-data", "${GLPI_DIR}/config", "${GLPI_DIR}/files", "${GLPI_DIR}/marketplace", "/var/log/nginx" ]

COPY --chown=root:root --chmod=755 conf/entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

WORKDIR ${GLPI_DIR}/
EXPOSE 80 443
CMD ["start"]
