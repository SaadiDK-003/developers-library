# Cursor IDE

♦ Stuff related to Cursor will be uploaded here...

### How to Install Cursor the AI Editor on Linux

1. Step 1 Visit the Cursor website at https://cursor.so and click on the "Download" button.
> When the download is finished, a file with this extension `.AppImage`
#### what is this ".AppImage" extension?
> AppImage is a universal software package format that does not require the conventional installation method to be installed on Linux.
2. Do not click it immediately! For the file to function properly, we must first make it executable. To make the file executable, go to the Downloads folder (or the place where you downloaded the Cursor software) and execute this command.
```javascript
chmod +x cursor-[fileVersion].AppImage
```
 ### `if you run into a problem below`
 ```
 ./cursor-0.42.4x86_64.AppImage
dlopen(): error loading libfuse.so.2

AppImages require FUSE to run. 
You might still be able to extract the contents of this AppImage 
if you run it with the --appimage-extract option. 
See https://github.com/AppImage/AppImageKit/wiki/FUSE 
for more information
 ```
 ### `follow below process, If you didn't encounter this error, you can skip this step`
 - install libfuse2
 ```javascript
 sudo apt-get install libfuse2
 ```
 - now try again
 ```javascript
chmod +x cursor-[fileVersion].AppImage
```
3. Great! You can now run the .AppImage file either by running the command from the terminal or by opening the Cursor file directly from your Downloads folder
```javascript
./cursor-[fileVersion].AppImage
```
### How to add cursor app on the installed application list
Follow these steps to add Cursor to your applications list

- Move the app from the download to opt folder
```javascript
sudo mv cursor-[fileVersion].AppImage /opt/cursor.appimage
```
- Create a desktop entry for Cursor by running the command
```javascript
sudo nano /usr/share/applications/cursor.desktop
```
- Past the follow in the file you've just created
```javascript
[Desktop Entry]
Name=Cursor
Exec=/opt/cursor.appimage
Icon=/opt/cursor.png
Type=Application
Categories=Development;
```
- Save the file.
> As Final Step, we should add an icon to the app so you can tell it apart from other applications

> Since we moved the app into the `/opt directory`, add a .png image into the `/opt directory` as well

> The image file should be named `cursor.png` as defined when we created the desktop entry.