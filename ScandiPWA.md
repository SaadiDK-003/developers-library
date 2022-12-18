# ScandiPWA ~ is the framework for magento which is based on React & GraphQL & use with magento.

♦ Stuff related to ScandiPWA will be uploaded here...

#### To learn ScandiPWA I can help you with `many` websites and `many` YouTube channels you can follow along, these are the best sources that We personally recommended which has industry standards.

### Websites:

- [scandipwa Official](https://scandipwa.com/)
- [snyk.io](https://snyk.io/test/npm/@scandipwa/magento-scripts/1.0.0)
- [patterns-of-scandipwa](https://docs.scandipwa.com/tutorials/video-tutorials/patterns-of-scandipwa)
- [creating-magento-2-module](https://docs.scandipwa.com/tutorials/scandipwa-social-share/step-1-and-2-creating-magento-2-module)
- [-magento-3d-model](https://docs.scandipwa.com/tutorials/product-3d-model-extension/part-1-magento-3d-model-uploads)

### YouTube Channels :

- [CodilarMagentoDevelopmentCompanyIndia](https://www.youtube.com/watch?v=vX0eWIP_TLc&ab_channel=Codilar%7CMagentoDevelopmentCompanyIndia)
- [ScandiPWA Offical](https://www.youtube.com/c/ScandiPWA)

### Create React Project :

```
npx create-scandipwa-app my-app
```

# Install ScandiPWA theme in Existing Magento 2 ?

> First check version of node & redis :

```
node -v & redis-cli -v
```

### if your are not install magento 2 yet follow this [Link](https://github.com/SaadiDK-003/developers-library/blob/master/magento.md) to Install.

### Before all the steps make sure your node & redis-cli is running..

## Install the ScandiPWA Theme :

We recommend you keep your theme source in a src/localmodules directory. You will then be able to configure composer to install the theme from here as a local module.

```
mkdir src/localmodules
cd src/localmodules
```

## Then install the ScandiPWA :

```
npx create-scandipwa-app my-app
```

## Then go to your root dir of magento :

```
composer config repo.theme path src/localmodules/<your-app-name>
```

```
composer install && composer update
```

## Then go to the dir of scandiPWA theme :

```
cd src/localmodules
BUILD_MODE=magento yarn build
```

## Then come again in to magento dir where your magento is install :

```
composer require scandipwa/<your-app-name>
```

## Enable the ScandiPWA theme :

```
bin/magento setup:upgrade
bin/magento cache:disable full_page
bin/magento cache:flush
```

## After all of that steps follow change the env.php file to show the theme go app/etc/env.php :

```
'cache' => [
    'persisted-query' => [
        'redis' => [
            'host' => '<REDIS HOST>',
            'scheme' => 'tcp',
            'port' => '<REDIS PORT>',
            'database' => '5'
        ]
    ]
]

```

## To See any change in your theme :

```
cd src/localmodules
BUILD_MODE=magento yarn start
```

### Disclaimer :

It would be best if you researched on react after the js on yourself I put your best reference but not worth I put that reference which is the best on the internet yet.

We Our Add more references & links in this repository near future.
