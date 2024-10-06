# NetSuite - SuiteCommerce
♦ Stuff releated to `SuiteCommerce` will be uploaded here...

## Set Up Theme Developer Tools
### Prerequisites
> Before downloading the theme developer tools, complete the following tasks:
* Install `Node.js` and Install `Gulp.js`.
## Download Theme Developer Tools
> Locate and download the theme developer tools appropriate for your implementation as described in the following procedure.

* To download and extract theme developer tools:
1. Log in to your NetSuite account.
2. In NetSuite, go to Documents > Files > File Cabinet.
3. Navigate to SuiteBundles/Bundle 521562/.
4. Download the .zip file you find there:
### ThemeDevelopmentTools-24.1.`x`.zip (where `x` equals the latest minor release).
5. Extract the .zip file to a location in your local environment. This becomes your root development directory for custom themes.
6. Open a command line or terminal window.
7. Access your root development directory created previously.
8. Enter the following command to install required Node.js packages into this directory:
```php
npm install
```
## Using Theme Developer Tools with Token-Based Authentication
1. Create an integration record.

For more information, see [Create Integration Records for Applications to Use TBA.](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/bridgehead_4249032125.html)

* In the Name field, enter a name for the integration record.
* In the State field, select Enabled.
* Check the Token-Based Authentication box.
* Check the TBA: Authorization Flow box.
* In the Callback URL field, enter: http://localhost:7777/tba.
* Clear the Authorization Code Grant box.
* Check the User Credentials box.
2. Save the integration. Be sure to copy the consumer key/secret before closing the page.
3. Paste the consumer `key/secret` in the `.env` file.

## Theme Development Files and Folders
* When you initially run the gulp theme:fetch command, this directory contains all downloaded and customized theme and extension HTML, Sass, and asset files. This is the directory where you develop and maintain all of your theme and extension customizations.
### File/Folder ~  `Workspace/`
```javascript
gulp theme:fetch
```
* When you run the gulp theme:local command, this directory contains all of the files associated with the compiled application used by the local server. When you run gulp theme:local, `Gulp.js` deploys the contents of this directory to the local Node.js server.
### File/Folder ~ `LocalDistribution/` Do not manually edit the files in this directory.
```javascript
gulp theme:local
```
* When you run the gulp theme:deploy command, this directory contains all of the files associated with the compiled application. After compilation, Gulp.js deploys the contents of this directory to your NetSuite file cabinet.
### File/Folder ~ `DeployDistribution/` Do not manually edit the files in this directory.
```javascript
gulp theme:deploy
```
### [For Details Visit here...](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_1497018780.html#subsect_1510180046)