# Magento 2
♦ Stuff releated to `Magento 2` will be uploaded here...

### Before doing this please checkout `Ubuntu Section` [Install Ubuntu and useful stuff to start with Magento](https://github.com/SaadiDK-003/developers-library/blob/master/ubuntu.md)

## Magento 2 `-` System requirements
| Software dependencies | 2.4.5-p1 | 2.4.5 | 2.4.4-p2 | 2.4.4 | 2.4.3-p3 | 2.4.3 |
| --------------------- | :------: | :---: | :------: | :---: | :------: | :---: |
| Composer              |   2.2    |   2.2    |   2.1    |   2.1    |   1      |   1      |
| Elasticsearch         |   7.17   |   7.17   |   7.16   |   7.16   |   7.16   |   7.10   |
| MariaDB               |   10.4   |   same   |   same   |   same   |   same   |   same   |
| MySQL                 |   8.0    |   same   |   same   |   same   |   same   |   same   |
| PHP                   |   8.1    |   same   |   same   |   same   |   7.4    |   same   |

#### Magento Open Source ~ `Composer` link
* change `<install-directory-name>` to your directory.
* if you need to install specific version of magento then add `={version-number}` after `edition` e.g. `edition=2.4.5`
```javascript
sudo composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition <install-directory-name>
```
#### Set file permissions
* You must set read-write permissions for the web server group before you install the Magento software. This is necessary so that the command line can write files to the Magento file system.
```python
cd /var/www/html/<magento install directory>
sudo find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
sudo find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
sudo chown -R :www-data .
sudo chmod u+x bin/magento
```
#### Install Magento
```python
sudo bin/magento setup:install \
--base-url=http://example.com \
--db-host=localhost \
--db-name=magento \
--db-user=root \
--db-password=your_password \
--admin-firstname=admin \
--admin-lastname=admin \
--admin-email=admin@admin.com \
--admin-user=admin \
--admin-password=admin123 \
--language=en_US \
--currency=USD \
--timezone=America/Chicago \
--use-rewrites=1 \
--search-engine=elasticsearch7 \
--elasticsearch-host=localhost \
--elasticsearch-port=9200 \
--elasticsearch-index-prefix=magento2 \
--elasticsearch-timeout=15 
```

```python
bin/magento help setup:install
```

### ♦ Issues sometimes you might encounter
1. If it's a PHP extension missing issue you can run this line of code in your terminal.

```python
sudo apt install php libapache2-mod-php php-common php-gmp php-curl php-soap php-bcmath php-intl php-mbstring php-xmlrpc php-mysql php-gd php-xml php-cli php-zip
```
---
#### If you have PHP 7.4 or lower version use with version number as mention below.
---
```python
sudo apt install php7.4 libapache2-mod-php7.4 php7.4-common php7.4-gmp php7.4-curl php7.4-soap php7.4-bcmath php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-mcrypt php7.4-mysql php7.4-gd php7.4-xml php7.4-cli php7.4-zip
```
2. Or sometimes you might need to change in php.ini and it can be these lines to be update.
```python
sudo subl /etc/php/7.4/apache2/php.ini
```
```javascript
file_uploads = On
allow_url_fopen = On
short_open_tag = On
memory_limit = 512M
upload_max_filesize = 128M
max_execution_time = 3600
```
```python
sudo systemctl restart apache2.service
```

### Magento Commonly Used Commands:
```python
sudo php bin/magento setup:upgrade
sudo php bin/magento setup:di:compile
sudo php bin/magento setup:static-content:deploy -f
sudo php bin/magento indexer:reindex
sudo php bin/magento cache:flush

sudo chmod -R 777 pub/ generated/ var/
```
### Easy way to run all commands at once:
> `but it is good to write commands and remember them, then use it like this with "&&" operator.`
```python
sudo php bin/magento setup:upgrade && sudo php bin/magento setup:di:compile && sudo php bin/magento setup:static-content:deploy -f && sudo php bin/magento indexer:reindex && sudo php bin/magento cache:flush && sudo chmod -R 777 pub/ generated/ var/
```
---
### For Front-end developers it is useful to run this command when ever you update `_module.less` or any sort of `.less` file.
```python
sudo rm -rf var/* pub/static/* && sudo php bin/magento cache:flush && sudo chmod -R 777 pub/ generated/ var/
```
### How to disable Magento 2 `Content Security Policy`

```
sudo php bin/magento module:disable Magento_Csp
```