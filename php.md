# PHP ~ Hypertext Preprocessor

♦ Stuff related to PHP will be uploaded here...

### PHP is a back-end language which is widely used in making websites, like `WordPress`, `Magento` even `Facebook` built on this.

#### You can visit `w3schools` to start learning it.

- [w3schools PHP](https://www.w3schools.com/php/)

#### Switch between PHP Versions:

```php
sudo update-alternatives --config php
```
> when you run above command it will show something like this

```php
There are 5 choices for the alternative php (providing /usr/bin/php).

  Selection    Path                  Priority   Status
------------------------------------------------------------
  0            /usr/bin/php.default   100       auto mode
  1            /usr/bin/php.default   100       manual mode
* 2            /usr/bin/php7.2        72        manual mode
  3            /usr/bin/php7.3        73        manual mode
  4            /usr/bin/php7.4        74        manual mode
  5            /usr/bin/php8.1        81        manual mode

Press <enter> to keep the current choice[*], or type selection number: 

```
> select the version you want by selecting a number from 0 - 5

> after that you need to enable the selected version mod and disable the current php verision mod for perfectly using the version you wanna use.

#### Example:
```
sudo a2enmod php7.2
```
```
sudo a2dismod php8.1
```
