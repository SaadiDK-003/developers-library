# Twig ~ Template Engine for PHP

♦ Stuff related to Twig will be uploaded here...

#### How to set and call a variable
* we use double curly braces to call a variable.
    * example: `{{`variable`}}`
* to set a variable.
    * example: `{%` set variable = 'Your String' `%}`
    * example: `{%` set variable = [1, 2] `%}` etc.
---
#### Calling a loop function
```javascript
{% for item in navigation %}
    <li><a href="{{ item.href }}">{{ item.caption }}</a></li>
{% endfor %}
```
* unlike other languages it has only `for` loop.

#### To comment in Twig
```php
{#
 your comment or code goes here...
#}
```