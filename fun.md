# Cool Stuff ~ Just Random Things

## Console Log

#### `%s` for string
```javascript
let name = "Alice";
console.log("Hello, %s!", name);
```
### `%d` or `%i` for integer
```javascript
let age = 30;
console.log("You are %d years old.", age);
console.log("Your age is %i.", age);
```

### `%f` for float
```javascript
let price = 19.99;
console.log("The price is $%.2f.", price); // .2f specifies 2 decimal places
```

### `%o` for optimal formatting of an object
```javascript
let user = { name: "Bob", occupation: "Developer" };
console.log("User details: %o", user);
```

### `%O` for default formatting of an object (similar to %o in many cases)
```javascript
let data = [1, 2, { key: "value" }];
console.log("Data array: %O", data);
```

### `%c` for custom CSS styling (often used for colorful console messages)
```javascript
console.log("%c 🚀 Customize Your Console Log with styling", "font-weight: 600; font-size: 12px; background: rgb(105,58,180); background: linear-gradient(117deg, rgba(105,58,180,1) 0%, rgba(253,29,29,1) 50%, rgba(90,69,252,1) 100%); color: #ffffff; padding: 4px 5px; border-radius: 15px");
```