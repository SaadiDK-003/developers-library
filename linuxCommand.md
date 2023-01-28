# Linux ~ Fun with Terminal.

♦ Stuff related to Linux will be uploaded here...

### Linux Commands:
- [ Linux Commands](https://www.xmind.net/m/WwtB/)

### Creating `tar.gz` file on Linux as follows:
- `here directory is the file or folder that you wanna zip`
```javascript
tar -czvf file.tar.gz directory
```
### Extracting `tar.gz` file on Linux as follows:
- x – instructs tar to extract the files from the zipped file
- v – means verbose, or to list out the files it’s extracting
- z – instructs tar to decompress the files – without this, you’d have a folder full of compressed files
- f – tells tar the filename you want it to work on
```javascript
tar –xvzf file.tar.gz
```
### To instruct `tar` to put the extracted unzipped files into a specific `directory`, enter this command:
```javascript
tar –xvzf file.tar.gz –C /home/user/destination
```
### Covnert `{ .png | .jpg | .jpeg }` files into `.webp` format.
---
* ### `-q [ number | range 0-100 ]` for quality.
* ### `-o` is for output.
```javascript
cwebp -q 60 linux.png -o linux.webp
```