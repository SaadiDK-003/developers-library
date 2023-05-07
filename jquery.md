# JQuery

♦ Stuff related to JQuery will be uploaded here...

### JQuery is a JavaScript Library that makes it easy for a developer to do more and write less.

#### You can visit `w3schools` to start learning it.
* [w3schools JQuery](https://www.w3schools.com/jquery/default.asp)

---
### Show Dialog element with the help of JQuery
```javascript
$.fn.extend({showModal: function() {
    return this.each(function() {
    if(this.tagName=== "DIALOG"){
            this.showModal();
        }
    });
}});
```
* need to add the above code before using it with JQuery else use the vanilla JS to perform it.
#### Example ~ Vanilla JS:
* let dialog = document.querySelector(`[your-selector-here]`);
* dialog.`showModal()`;
#### Example ~ JQuery
* $(`[your-selector-here]`).`showModal()`;
> Because by default JQuery don't have `showModal()` function.
---
#### Also to `close` if it is clicked outside the dialog box.
* We can add the below code in our JS.
```javascript
dialog.addEventListener("click", function (e) {
    const dialogDimensions = dialog.getBoundingClientRect();
    console.log(dialogDimensions);
    if (
    e.clientX < dialogDimensions.left ||
    e.clientX > dialogDimensions.right ||
    e.clientY < dialogDimensions.top ||
    e.clientY > dialogDimensions.bottom
    ) {
    modal.close();
    }
});
```
> The good thing is `Esc` key is work by default to close the dialog, which is pretty nice.