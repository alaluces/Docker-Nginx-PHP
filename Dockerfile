FROM php:7.2.10-fpm-stretch

LABEL maintainer="alaluces"

RUN apt-get update && apt-get install -y  \
    libpng-dev \
    libjpeg-dev \
    nginx \
    supervisor \
    && docker-php-ext-install -j$(nproc) mysqli \
    && docker-php-ext-install -j$(nproc) bcmath

RUN pecl install redis-4.0.1 \
    && docker-php-ext-enable redis 

RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install -j$(nproc) gd

RUN  mkdir -p /etc/nginx/sites-enabled /autostart /etc/ssl/certs/custom 

# Configure nginx
COPY ./files/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./files/nginx/default_server.conf /etc/nginx/sites-enabled/default.conf
COPY ./files/src/ /var/www/html/

COPY ./files/php/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf
COPY ./files/php/php.ini /usr/local/etc/php/php.ini

# Configure supervisord
COPY ./files/supervisor/supervisord.conf /etc/supervisor/conf.d/
COPY ./files/supervisor/init.d/* /autostart/

# SSL
#COPY ./files/ssl/ca.crt /etc/ssl/certs/custom/ca.crt
#COPY ./files/ssl/cert.crt /etc/ssl/certs/custom/cert.crt
#COPY ./files/ssl/privkey.key /etc/ssl/certs/custom/privkey.key

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 80 443 9000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
