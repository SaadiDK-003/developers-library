# WP CLI ~ WordPress Command Line Interface

♦ Stuff related to WP-CLI will be uploaded here...

### If you want to update wp site and home url here is the command.
```php
wp option update siteurl "https://yourdoman.com" && wp option update home "https://yourdoman.com"
```

>#### If you want to create a host + Virtual Host run it with this parameter below:
```javascript
sudo CREATE_VIRTUAL_HOST=1 bash install-wp.sh
```

>#### If you want to give 777 permission to wp directory pass this parameter below, this is because of images are not going into media directory because of permission issue:
```javascript
sudo INSECURE_PERMS=1 bash install-wp.sh
```

>#### If you want pas both parameters run this command:
```javascript
sudo INSECURE_PERMS=1 CREATE_VIRTUAL_HOST=1 bash install-wp.sh
```