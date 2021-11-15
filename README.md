# ar-symlink-generator
Links arweave data folders to storage drives using symbolic links.

## Usage
Open the bash file in your editor of choice and change the variables at the beginning of the script. You should also read through the script itself to validate the commands being executed. Your data will be at risk of erasure if the proper steps are not taken. The script may also need to be executed as root to access some protected directories.

Ensure that the file is given permissions to be executed:

``chmod +x filename.sh``

Then, simply execute the file (root privilages may be needed):

``./FILENAME.sh``

The file should then automatically move your files to the requested directories, keep in mind, it copies all of the files to the drives before removing them from the original directory, so the script can be stopped safely before completion, though it may result in redundant data.


## Requests
If you see any ways that this script can be improved, feel free to open an issue or message me on discord (LazerUnknown#2553).

I am currently working on improving the automatic handling of redundant files, and a way to automatically stop data copying when the drives reach capacity.

## License
MIT License.
