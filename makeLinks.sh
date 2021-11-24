#!/bin/bash

## Main areweave folder
ARWEAVEDIR=/path/to/your/main/folder
## Actual rocksdb folder
ROCKSDB=/path/to/your/rocksdb/folder
## Rocksdb drive mount point or folder on drive (will add support for multiple drives upon request)
ROCKSDBDRIVE=/path/to/your/rocksdb/drive/mount/point
## Actual chunks folder
CHUNKS=/path/to/your/chunks/folder
## List of chunks drives' mount points (or any empty directory for chunks)
## WARNING: THESE DIRECTORIES NEED TO BE EMPTY OF NON-CHUNK DATA, but can exist on a drive with other data
CHUNKSDRIVES=(/mnt/arweave/drives/1 /mnt/arweave/drives/2 /mnt/arweave/drives/3 /mnt/arweave/drives/.../possible/subdirectory)
## Path to the script you want to run at the end (if any).
FINALSCRIPT=/path/to/your/script.sh

## Whether or not you want to remove redundant files from chunks drives, could save space (EXPERIMENTAL, MOSTLY UNTESTED)
## This shouldn't have to be done every time the script is executed, but it can if you don't care about execution time.
REMOVEREDUNDANT=false

## If your directories are read/write protected, permission elevation is required (run script with sudo).
## WARNING: FAILIURE TO ELEVATE PERMISSIONS MAY RESULT IN DATA LOSS

## -----------------------SCRIPT START----------------------- ##

## Stop the miner.
cd $ARWEAVEDIR
./bin/stop

## Full archive of rocksdb to remote drive
echo "Copying files from rocksdb to remote..."
rsync --progress -aS --no-links "$ROCKSDB"/* $ROCKSDBDRIVE

## Linking surface folders to main rocksdb folder
echo "Linking files from remote to rocksdb..."
cd $ROCKSDBDRIVE
FILESTOLINK=$(ls)
for F in ${FILESTOLINK[@]}; do
	## If for some reason the file got deleted, relink it.
	if [[ ! -e "$ROCKSDB/$F" ]]; then
		ln -s "$ROCKSDBDRIVE/$F" $ROCKSDB
	fi
	## If the file exists but isn't a link (newly archived file)
	if [[ ! -L "$ROCKSDB/$F" ]]; then
  		rm -rf "$ROCKSDB/$F"
		ln -s "$ROCKSDBDRIVE/$F" $ROCKSDB
	fi
done
cd $ARWEAVEDIR

getLowest () {
	LOWEST=${CHUNKSDRIVES[0]}
	for DRIVE in ${CHUNKSDRIVES[@]}; do
		if [[ $(du $DRIVE) < $(du $LOWEST) ]]; then
			LOWEST=$DRIVE
		fi
	done
}

## Link all files in chunks_storage to a drive, spreading it evenly
## TODO: ADD A CHECK FOR A FULL DRIVE
echo "Copying files from chunks_storage to remote(s)..."
echo "DRIVES: ${CHUNKSDRIVES[@]}"
FILESTOCOPY=$(find "$CHUNKS"/* -type f)
for F in ${FILESTOCOPY[@]}; do
	getLowest
	echo "Now copying to $LOWEST"
	rsync --progress -S --no-links $F $LOWEST
done

## Get a list of all files on the chunks drives.
## Remove redundant files if that option is configured.
echo "Determining which files need to be linked in chunk remote(s)..."
CDFLIST=()
CDFPATHS=()
for CD in ${CHUNKSDRIVES[@]}; do
	cd $CD
	FILESTOLINK=$(ls)
	
	## Removes the redundant files if configured to do so.
	## This preserves the first instance of a file as to not break symlinks.
	## Program links files starting with the first drive, so a link will never break this way.
	for F in ${FILESTOLINK[@]}; do
		if [[ $REMOVEREDUNDANT ]]; then
			## If the file is already in the array (this check can be slow)
			if [[ " ${CDFLIST[*]} " =~ " $F " ]]; then
    			rm -rf "$CD/$F"
    		else
    			CDFLIST=(${CDFLIST[@]} $F)
    			CDFPATHS=(${CDFPATHS[@]} "$CD/$F")
			fi
		else
			## If not checking for redundancy, add them regardless
			CDFLIST=(${CDFLIST[@]} $F)
    		CDFPATHS=(${CDFPATHS[@]} "$CD/$F")
		fi
	done
done
cd $ARWEAVEDIR

## Link all files on these drives back to chunks_storage
echo "Linking files from remote(s) to chunk_storage"
for i in ${!CDFLIST[@]}; do
	F=${CDFLIST[i]}
	FP=${CDFPATHS[i]}
	## If for some reason the file got deleted, relink it.
	if [[ ! -e "$CHUNKS/$F" ]]; then
		ln -s $FP $CHUNKS
	fi
	## If the file exists but isn't a link (newly archived file)
	if [[ ! -L "$CHUNKS/$F" ]]; then
  		rm -rf "$CHUNKS/$F"
		ln -s $FP $CHUNKS
	fi
done
cd $ARWEAVEDIR

## This is the script you use to restart the mine/sync process
$FINALSCRIPT
