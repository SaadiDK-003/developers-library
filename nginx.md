# Nginx ~ (pronounced `engine-x`)

♦ Stuff related to Nginx will be uploaded here...

>### here is the link [Nginx guide](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-22-04) from where you can install `Nginx` on your system.
---
### Steps to config a website on server.
1. Create a folder inside `/var/www/html` directory.
```javascript
sudo mkdir -p /var/www/example
echo "<h1>example.com working</h1>" | sudo tee /var/www/example/index.html
sudo chown -R www-data:www-data /var/www/example
```
2. Create a nginx config file inside `sites-available` directory.
```javascript
sudo nano /etc/nginx/sites-available/example.conf
```
Paste:
```php
server {
    listen 80;
    listen [::]:80;

    server_name example.com www.example.com;

    root /var/www/example;
    index index.html index.htm;

    access_log /var/log/nginx/example.com.access.log;
    error_log  /var/log/nginx/example.com.error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```
Enable it:
```php
sudo ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/example.conf
```