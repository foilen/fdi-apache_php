# Description

An Apache PHP image that has a lot of PHP extensions installed and also a sendmail replacement that supports a lot of different ways of sending emails with PHP.

The sendmail replacement is https://github.com/foilen/sendmail-to-msmtp .

The PHP header to tell the application that it is protected by HTTPS is set when the load-balancer tells it that it is protected.

# Build and test

```
./create-local-release.sh

mkdir -p _test/log _test/sites-available _test/sites-enabled _test/www-1

cat > _test/sites-available/localhost-1.conf << _EOF
<VirtualHost *:80>
    ServerName localhost-1.foilen.com
    
    DocumentRoot /mount/www-1
    <Directory /mount/www-1/>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog "|/usr/bin/rotatelogs -n 1 /mount/log/localhost-1.foilen.com-error.log 100M"
    CustomLog "|/usr/bin/rotatelogs -n 1 /mount/log/localhost-1.foilen.com-access.log 100M" combined
</VirtualHost>
_EOF

cat > _test/www-1/index.php << _EOF
<?php
phpinfo();
_EOF

ln -s ../sites-available/localhost-1.conf _test/sites-enabled/

docker run -ti --rm \
    -v $PWD/_test/log/:/mount/log \
    -v $PWD/_test/sites-available/:/etc/apache2/sites-available/ \
    -v $PWD/_test/sites-enabled/:/etc/apache2/sites-enabled/ \
    -v $PWD/_test/www-1/:/mount/www-1 \
    -p 80:80 -p 443:443 \
    -e USER_ID=$(id -u) \
    -e USER_GID=$(id -g) \
    --name allsites \
    fdi-apache_php:main-SNAPSHOT

curl http://localhost-1.foilen.com

```

# Available environment config and their defaults

- USER_ID
- USER_GID

- PHP_MAX_EXECUTION_TIME_SEC=300
- PHP_MAX_UPLOAD_FILESIZE_MB=64
- PHP_MAX_MEMORY_LIMIT_MB=192
    - must be at least 3 times PHP_MAX_UPLOAD_FILESIZE_MB

- EMAIL_DEFAULT_FROM_ADDRESS
- EMAIL_HOSTNAME
- EMAIL_PORT
- EMAIL_USER
- EMAIL_PASSWORD

- CERTBOT_EMAIL
- CERTBOT_DOMAINS

## Cron

You can provide cron lines with environment starting with "CRON_". Eg:
- 'CRON_1=* * * * * www-data echo yay | tee /tmp/yay_cron.log'

# Usage

## Example with Let's Encrypt

```
# Configure site
mkdir -p \
  $HOME/letsencrypt \
  $HOME/logs \
  $HOME/sites/test-wp \
  $HOME/sites-available \
  $HOME/sites-enabled

cat << _EOF > $HOME/sites-available/test-wp.foilen.com.conf
<VirtualHost *:80>
    ServerName test-wp.foilen.com
    
    DocumentRoot /mount/test-wp
    <Directory /mount/test-wp/>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog "|/usr/bin/rotatelogs -n 1 /mount/log/test-wp-error.log 100M"
    CustomLog "|/usr/bin/rotatelogs -n 1 /mount/log/test-wp-access.log 100M" combined
</VirtualHost>
_EOF

ln -s ../sites-available/test-wp.foilen.com.conf $HOME/sites-enabled/

docker rm -f allsites ; \
docker run -d --restart always \
    -v $HOME/logs/:/mount/log \
    -v $HOME/logs/:/var/log/letsencrypt \
    -v $HOME/sites-available/:/etc/apache2/sites-available/ \
    -v $HOME/sites-enabled/:/etc/apache2/sites-enabled/ \
    -v $HOME/sites/test-wp/:/mount/test-wp \
    -v $HOME/letsencrypt/:/etc/letsencrypt \
    -p 80:80 -p 443:443 \
    -e USER_ID=$(id -u) \
    -e USER_GID=$(id -g) \
    -e CERTBOT_EMAIL=test@foilen.com \
    -e CERTBOT_DOMAINS=test-wp.foilen.com \
    --name allsites \
    foilen/fdi-apache_php:0.0.2 && \
docker logs -f allsites
```
