# VSC ~ Visual Studio Code

♦ Stuff related to VSC will be uploaded here...

### VS Code - Add a new file or folder under the selected working directory

#### Edit shortcuts file

1. Hit `Cmd` + `Shift` + `P` and then find `Preferences: Open Keyboard Shortcuts (JSON)` open this file.
2. after opening this file you will see something like this.
```javascript
// Place your key bindings in this file to override the defaults
[
]
```
3. add the below lines and then try adding new `file` or `folder`.
```javascript
// Place your key bindings in this file to override the defaults
[
    { "key": "ctrl+n", "command": "explorer.newFile", "when": "explorerViewletFocus" },
    { "key": "ctrl+shift+n", "command": "explorer.newFolder", "when": "explorerViewletFocus" }
]
```