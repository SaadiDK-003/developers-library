# Laravel ~ PHP FrameWork

♦ Stuff related to Laravel will be uploaded here...
#### Laravel is a web application framework with expressive, elegant syntax. We’ve already laid the foundation — freeing you to create without sweating the small things.

### Commands that will be useful.
---
#### If you have created a `table schema` in project and wanted that table to update in `database` so run this command.
```javascript
php artisan migrate
```
* #### or if you are willing to update the specific table you can run this command.
```javascript
php artisan migrate:refresh --path={path to your table}
```
> here path can be looks like this eg.
>> database/migrations/2023_01_09_113112_create_messages_table.php