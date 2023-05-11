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
* `-q [ number | range 0-100 ]` for quality.
* `-o` is for output.
```javascript
cwebp -q 60 linux.png -o linux.webp
```
---
### Convert `{ .png | .jpg | .jpeg }` files in a `Direcory`.
```javascript
<?php
$directory = 'your-directory-path'; // Replace with the directory path where your PNG and JPG files are located

// Get all PNG and JPG files in the directory
$pngFiles = glob($directory . '/*.png');
$jpgFiles = glob($directory . '/*.jpg');

// Combine PNG and JPG files into a single array
$imageFiles = array_merge($pngFiles, $jpgFiles);

// Loop through each image file and convert it to WebP
foreach ($imageFiles as $imageFile) {
    $webpFile = pathinfo($imageFile, PATHINFO_FILENAME) . '.webp';
    
    // Determine the file type (PNG or JPG) and create the appropriate image object
    if (preg_match('/\.png$/i', $imageFile)) {
        $image = imagecreatefrompng($imageFile);
    } elseif (preg_match('/\.(jpeg|jpg)$/i', $imageFile)) {
        $image = imagecreatefromjpeg($imageFile);
    } else {
        continue; // Skip files that are not PNG or JPG
    }
    
    // Convert the image to WebP format with quality set to 80 (adjust as needed)
    imagewebp($image, $webpFile, 90);
    
    // Free up memory
    imagedestroy($image);
    
    echo '<pre>';
    echo "Converted $imageFile to $webpFile\n";
}

echo "Conversion completed!";
?>
```
* #### The above code will convert any `png | jpg | jpeg` file into `webp` format.
