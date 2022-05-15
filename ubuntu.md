# Ubuntu ~ 20.04.4

♦ Stuff related to Ubuntu will be uploaded here...

Downlaod Link [Ubuntu 20.04.4](https://releases.ubuntu.com/20.04.4/)

#### After installing:
* sudo apt upgrade
* sudo apt update
  * then restart PC

#### Optional but useful ~ for devs
* install VS Code `&` Sublime Text
* install Chrome `FireFox preinstalled`
* install FlameShot `very useful tool for taking screenShot and editing`

#### Install LAMP ~ ( Linux Apache MySQL PHP ) 
Source Link: [Install LAMP](https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-20-04)
* sudo a2enmod rewrite ~ `restart apache`

### OwnerShip
* sudo chown -R **`$USER:$USER`** /var/www/`your_domain` ~ in our case it is **`html`**

### Install Composer
Source Link: [Composer](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-composer-on-ubuntu-20-04)

#### Install ElasticSearch
Source Link: [ElasticSearch](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-20-04)

### Other Stuff ~ after doing all above things:

* **`Virtual Host`**
```python
sudo subl /etc/apache2/sites-available/000-default.conf
```
```python
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName magento.local
        ServerAlias magento.local
        DocumentRoot /var/www/html/Magento2
        ErrorLog ${APACHE_LOG_DIR}/Magento2.log
        CustomLog ${APACHE_LOG_DIR}/Magento2.log combined
        <Directory /var/www/html/Magento2>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>
```
```php
sudo systemctl reload apache2
```
* **`Hosts`** ~ file
```javascript
sudo subl etc/hosts
``` 


