# Ubuntu ~ 20.04.4

♦ Stuff related to Ubuntu will be uploaded here...

- Downlaod Link [Ubuntu 20.04.4](https://releases.ubuntu.com/20.04.4/)
- Download Link [Ubuntu 22.04.1](https://releases.ubuntu.com/22.04/)

#### After installing:

- sudo apt upgrade
- sudo apt update
  - then restart PC

#### Optional but useful ~ for devs

- install VS Code `&` Sublime Text
- install Chrome `FireFox preinstalled`
- install FlameShot `very useful tool for taking screenShot and editing`
- Install [phpMyAdmin](https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-on-ubuntu-20-04) or [Dbeaver](https://computingforgeeks.com/install-and-configure-dbeaver-on-ubuntu-debian/) for MySQL ease of access.

#### Install LAMP ~ ( Linux Apache MySQL PHP )

Source Link: [Install LAMP](https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-20-04)

#### MySQL set `root` Password ~ `most of the time people get into this problem` ~ because by default root user comes with `no-password`
- [How To Reset Your MySQL  Root Password ~ Digitalocean](https://www.digitalocean.com/community/tutorials/how-to-reset-your-mysql-or-mariadb-root-password-on-ubuntu-20-04)
- [How to Change MySQL Root Password in Ubuntu ~ linuxhint](https://linuxhint.com/change-mysql-password-ubuntu-22-04/)

#### This is a very useful command to enable .htaccess and other type of functionality
- sudo a2enmod rewrite ~ `restart apache`

### OwnerShip

- sudo chown -R **`$USER:$USER`** /var/www/`your_domain` ~ in our case it is **`html`**

### Install Composer

Source Link: [Composer](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-composer-on-ubuntu-20-04)

> if you need to `upgrade` or `downgrade` composer version use the command below:
- here `number` will be depends e.g. `1` or `2`
```
sudo composer self-update --number
```

#### Install ElasticSearch

Source Link: [ElasticSearch](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-20-04)

#### set the memory limit for `elasticsearch`.
```
sudo nano /etc/elasticsearch/jvm.options
```
> update these two lines according to your need.
* -Xms1g 
* -Xmx1g 

### Other Stuff ~ after doing all above things:

- **`Virtual Host`**

```python
sudo subl /etc/apache2/sites-available/000-default.conf
```

#### Here you can see I have set `ServerName & ServerAlias` as `magento.local` you can set as you want.

#### `DocumentRoot & Directory` the path should be like this if you have diffrent folder name `/var/www/html/[your_folder_name]` .

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

- **`Hosts`** ~ file

```javascript
sudo subl /etc/hosts
```

> after opening hosts file add this `127.0.0.1 magento.local`

![hosts file preview](https://github.com/SaadiDK-003/developers-library/blob/master/img/hosts_file.PNG "Hosts File Preview")


# Ubuntu Commands ♦

> To install any `.deb` file.
```javascript
sudo dpkg -i example.deb
```
> Create any file
```
touch example.txt
```
> Open any folder from `terminal`
```javascript
xdg-open [folder path]  
```
> Find a file in `directory`
```python
ls | grep "name-of-file"
```
> Get your public `SSH` Key
```javascript
cat ~/.ssh/id_rsa.pub
```
---
## Creating Swap File in Ubuntu ~  Thanks to [Saif Bin Zahid](https://github.com/saif-bin-zahid)
---
```
sudo swapoff /swapfile
```
```
sudo rm /swapfile
```
> Create new swap space of size 16 GB (16 * 1024 = 16384). bs is the block size. Basically bs * count = bytes to be allocated (in this case 16 GB). Here bs = 1M (M stands for mega, so we are assigning 1MB block size) and we are allocating 16384 * 1MB (=16GB) to swap.
```
sudo dd if=/dev/zero of=/swapfile bs=1M count=16384
```
> Give it the read/write permission for root
```
sudo chmod 600 /swapfile
```
> Format it to swap
```
sudo mkswap /swapfile
```
> Turn on swap again
```
sudo swapon /swapfile
```
> Now reboot the PC for the above changes to take place.