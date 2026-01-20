# Nginx ~ (pronounced `engine-x`)

♦ Stuff related to Nginx will be uploaded here...

>### here is the link [Nginx guide](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-22-04) from where you can install `Nginx` on your system.
---
### Steps to config a website on server.
* #### Create a folder inside `/var/www/html` directory.
```javascript
sudo mkdir -p /var/www/html/example
sudo tee /var/www/html/example/index.php > /dev/null <<'PHP'
<?php
phpinfo();
PHP
sudo chown -R www-data:www-data /var/www/html/example
```
* #### Install PHP-FPM + common extensions.
```php
sudo apt update
sudo apt install -y nginx php8.3-fpm php8.3-cli php8.3-mysql php8.3-curl php8.3-mbstring php8.3-xml php8.3-zip php8.3-gd php8.3-intl
sudo systemctl enable --now php8.3-fpm nginx
```
>Check FPM socket:
```php
ls -l /run/php/
# expect: php8.3-fpm.sock
```
* #### Create a nginx config file inside `sites-available` directory.
```javascript
sudo nano /etc/nginx/sites-available/example.conf
```
>Paste:
```php
server {
    listen 80;
    listen [::]:80;

    server_name example.com www.example.com;

    root /var/www/html/example;
    index index.php index.html;

    access_log /var/log/nginx/example.access.log;
    error_log  /var/log/nginx/example.error.log;

    # Security: don't serve hidden files (.env, .git, etc.)
    location ~ /\.(?!well-known).* {
        deny all;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;

        # Helpful defaults
        fastcgi_read_timeout 300;
    }

    # Optional: cache static files
    location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg|woff2?)$ {
        expires 30d;
        access_log off;
    }
}
```
>Enable it:
```php
sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/example.conf
```
>Disable the default site (recommended so it doesn’t “catch” your domain):
```php
sudo rm -f /etc/nginx/sites-enabled/default
```
>Test + reload:
```php
sudo nginx -t && sudo systemctl reload nginx
```
>Now open: http://example.com (phpinfo should show).
---
### HTTPS (`Let’s Encrypt`) on Hostinger VPS — the correct `Certbot` method

* #### Install dependencies
```php
sudo apt update
sudo apt -y install python3 python3-venv libaugeas0
```
* #### Install Certbot for Nginx
```php
sudo python3 -m venv /opt/certbot
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
```
### Add `SSL` with `Certbot` (when DNS is correct)
```php
sudo certbot --nginx -d example.com -d www.example.com
```
>And verify:
```php
sudo certbot renew --dry-run
```

## Laravel best-practice vhost (important)
* Laravel must point to `/public`.
* Config:
```php
server {
    listen 80;
    listen [::]:80;

    server_name myapp.com www.myapp.com;

    root /var/www/html/myapp/public;
    index index.php;

    access_log /var/log/nginx/myapp.access.log;
    error_log  /var/log/nginx/myapp.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```
## PHP settings you’ll actually change (correct way)

### A) CLI vs FPM configs are different
* #### CLI config:
```php
php -i | grep "Loaded Configuration File"
```
* #### FPM config:
```php
php-fpm8.3 -i | grep "Loaded Configuration File" || true
```
>Most common file:
* #### `/etc/php/8.3/fpm/php.ini`
```php
sudo nano /etc/php/8.3/fpm/php.ini
```
* ### Typical values:
  * `memory_limit = 512M`
  * `upload_max_filesize = 64M`
  * `post_max_size = 64M`
  * `max_execution_time = 300`