FROM php:8.2.16-apache

# Let's encrypt
RUN export TERM=dumb ; export DEBIAN_FRONTEND=noninteractive ; apt-get update && apt-get install -y \
    certbot python3-certbot-apache \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Apache and PHP modules
RUN export TERM=dumb ; export DEBIAN_FRONTEND=noninteractive ; apt-get update && apt-get install -y \
    libapache2-mod-fcgid \
    libfreetype6-dev \
    libjpeg-dev \
    libonig-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN a2enmod fcgid headers proxy proxy_fcgi proxy_http rewrite ssl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
      gd mbstring opcache pdo xml zip \
      mysqli pdo_mysql \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Extra applications
RUN export TERM=dumb ; export DEBIAN_FRONTEND=noninteractive ; apt-get update && apt-get install -y \
    cron exim4-daemon-light- ssmtp- \
    msmtp \
    gnupg2 \
    imagemagick \
    curl less vim wget \
    zip unzip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Sending emails easily
RUN wget https://deploy.foilen.com/sendmail-to-msmtp/sendmail-to-msmtp_1.1.1_amd64.deb && \
  dpkg -i sendmail-to-msmtp_1.1.1_amd64.deb && \
  rm sendmail-to-msmtp_1.1.1_amd64.deb

# ImageMagick can create PDF
COPY assets/policy.xml /etc/ImageMagick-6/policy.xml

# Init script
COPY assets/init.sh /
RUN chmod u+x /init.sh

EXPOSE 80 443

CMD /init.sh
