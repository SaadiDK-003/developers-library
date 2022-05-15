# Magento 2
♦ Stuff releated to `Magento 2` will be uploaded here...

#### Magento Open Source ~ `Composer` link
* change `<install-directory-name>` to your directory.
```php
$ sudo composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition <install-directory-name>
```
#### Set file permissions
* You must set read-write permissions for the web server group before you install the Magento software. This is necessary so that the command line can write files to the Magento file system.
```php
cd /var/www/html/<magento install directory>
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R :www-data . # Ubuntu
chmod u+x bin/magento
```
#### Install Magento
```php
$ bin/magento setup:install \
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