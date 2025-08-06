FROM php:8.2-apache

# Install system dependencies and required PHP extensions
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    nano \
    tzdata \
    sudo \
    cron \
    unzip \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions (8.2 equivalents of your 8.1 list)
RUN docker-php-ext-install \
    pdo_mysql \
    zip \
    gd \
    mbstring \
    curl \
    xml \
    bcmath \
    opcache

# Install rclone
RUN curl https://rclone.org/install.sh | bash

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i \
        -e "s/^ *memory_limit.*/memory_limit = 512G/g" \
        -e "s|short_open_tag = Off|short_open_tag = On|g" \
        -e "s|post_max_size = 8M|post_max_size = 256M|g" \
        -e "s|upload_max_filesize = 2M|upload_max_filesize = 256M|g" \
        -e 's|;date.timezone =|date.timezone = Europe/Bucharest|g' \
        -e "s|;opcache.enable=1|opcache.enable=1|g" \
        -e "s|;opcache.memory_consumption=128|opcache.memory_consumption=128|g" \
        -e "s|;opcache.max_accelerated_files=10000|opcache.max_accelerated_files=30000|g" \
        /usr/local/etc/php/php.ini

RUN echo "upload_max_filesize = 256M" >> /usr/local/etc/php/php.ini  && \
   echo "post_max_size = 512M" >> /usr/local/etc/php/php.ini

# Configure Apache to handle files without .php extension
RUN echo "<FilesMatch \.php$>" > /etc/apache2/conf-available/php-handler.conf && \
   echo "    SetHandler application/x-httpd-php" >> /etc/apache2/conf-available/php-handler.conf && \
   echo "</FilesMatch>" >> /etc/apache2/conf-available/php-handler.conf && \
   a2enconf php-handler

RUN echo "<Directory /var/www/html>" > /etc/apache2/sites-available/000-default.conf && \
    echo "    Options Indexes FollowSymLinks">> /etc/apache2/sites-available/000-default.conf && \
    echo "    AllowOverride All" >> /etc/apache2/sites-available/000-default.conf && \
    echo "    Require all granted" >> /etc/apache2/sites-available/000-default.conf && \
    echo "</Directory>" >> /etc/apache2/sites-available/000-default.conf && \
    echo "<FilesMatch \.php$>" >> /etc/apache2/sites-available/000-default.conf && \
    echo "    SetHandler application/x-httpd-php" >> /etc/apache2/sites-available/000-default.conf && \
    echo "</FilesMatch>" >> /etc/apache2/sites-available/000-default.conf
    
# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set timezone (adjust as needed)
ENV TZ=Europe/Bucharest
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Configure Apache document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

HEALTHCHECK --interval=1m --timeout=10s CMD curl --fail http://127.0.0.1:80

# Configure Apache
RUN a2enmod rewrite && a2dismod autoindex -f

WORKDIR /var/www/html
EXPOSE 80

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
