# Magento 2
♦ Stuff releated to `Magento 2` will be uploaded here...

### Before doing this please checkout `Ubuntu Section` [Install Ubuntu and useful stuff to start with Magento](https://github.com/SaadiDK-003/developers-library/blob/master/ubuntu.md)

#### Magento Open Source ~ `Composer` link
* change `<install-directory-name>` to your directory.
```javascript
sudo composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition <install-directory-name>
```
#### Set file permissions
* You must set read-write permissions for the web server group before you install the Magento software. This is necessary so that the command line can write files to the Magento file system.
```python
cd /var/www/html/<magento install directory>
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R :www-data . # Ubuntu
chmod u+x bin/magento
```
#### Install Magento
```python
bin/magento setup:install \
--base-url=http://localhsot/your_dir \
--db-host=localhost \
--db-name=magento \
--db-user=magento \
--db-password=magento \
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
--elasticsearch-host=es-host.example.com \
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
sudo apt install php7.4 libapache2-mod-php7.4 php7.4-common php7.4-gmp php7.4-curl php7.4-soap php7.4-bcmath php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-mcrypt php7.4-mysql php7.4-gd php7.4-xml php7.4-cli php7.4-zip
```
