# Base image
FROM ubuntu:20.04

# Maintainer
LABEL maintainer="mohmmadkhir22@gmail.com"

# Environment variables to disable interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    MYSQL_ROOT_PASSWORD=m1n1str4 \
    TZ=Europe/Amsterdam

# Update system and install dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    nginx \
    nginx-extras \
    unzip \
    memcached \
    php5 \
    php5-mysql \
    php-pear \
    nodejs \
    mysql-server \
    wget \
    tzdata && \
    apt-get clean

# Configure timezone
RUN echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Configure MySQL
RUN echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

# Expose MySQL to external connections
RUN sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf

# Set up Ministra portal
WORKDIR /var/www/html
RUN wget https://www.ucanbolat.nl/files/ministra_portal-5.3.0.zip && \
    unzip ministra_portal-5.3.0.zip && \
    mv ministra_portal-5.3.0 ministra_portal && \
    rm -rf *.zip

# Set up Apache and PHP configuration
RUN echo "short_open_tag = On" >> /etc/php5/apache2/php.ini && \
    a2enmod rewrite

# Configure Apache and NGINX
COPY 000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY ports.conf /etc/apache2/ports.conf
COPY default /etc/nginx/sites-available/default

# Set up Ministra database
RUN service mysql start && \
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE ministra_db;" && \
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON ministra_db.* TO ministra@localhost IDENTIFIED BY '1' WITH GRANT OPTION;"

# Deploy Ministra
WORKDIR /var/www/html/ministra_portal/deploy
RUN pear channel-discover pear.phing.info && \
    pear install -Z phing/phing && \
    phing

# Expose ports
EXPOSE 80 443 3306

# Start services
CMD service mysql start && \
    service apache2 start && \
    service nginx start && \
    tail -f /dev/null
