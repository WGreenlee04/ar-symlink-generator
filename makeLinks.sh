#!/bin/bash

## PUT THIS IN YOUR MAIN ARWEAVE FOLDER!!

./bin/stop
CWDIR=$(pwd)

## Actual rocksdb folder
ROCKSDB=/path/to/your/rocksdb/folder
## Rocksdb drive
ROCKSDBDRIVE=/path/to/your/rocksdb/drive
## Actual chunks folder
CHUNKS=/path/to/your/chunks/folder
## List of chunks drives
CHUNKSDRIVES=(/mnt/arweave/drives/1 /mnt/arweave/drives/2 /mnt/arweave/drives/3)
## Path to the script you want to run at the end (if any).
FINALSCRIPT=/path/to/your/script.sh

## Full archive of rocksdb to remote drive
echo "Copying files from rocksdb to remote"
rsync --progress -aS --no-links "$ROCKSDB"/* $ROCKSDBDRIVE

## Linking surface folders to main rocksdb folder
echo "Linking files from remote to rocksdb"
cd $ROCKSDBDRIVE
LNLIST=$(ls)
for L in ${LNLIST[@]}; do
	if [[ ! -e "$ROCKSDB/$L" ]]; then
		ln -s "./$L" $ROCKSDB
	fi
	if [[ ! -L "$ROCKSDB/$L" ]]; then
  		rm -rf "$ROCKSDB/$L"
		ln -s "./$L" $ROCKSDB
	fi
done
cd $CWDIR

## Link all files in chunks_storage to a drive, spreading it evenly
echo ${CHUNKSDRIVES[@]}
echo "Copying files from chunks_storage to remote(s)"
FLIST=$(find "$CHUNKS"/* -type f)
i=0
loop=${#CHUNKSDRIVES[@]}
for F in ${FLIST[@]}; do
	echo $i
	rsync --progress -S --no-links $F ${CHUNKSDRIVES[i]}
	((i=i+1))
	((i=i%loop))
done

## Link all files on these drives back to chunks_storage
echo "Linking files from remote(s) to chunk_storage"
for CD in ${CHUNKSDRIVES[@]}; do
	cd $CD
	LNLIST=$(ls)
	for LNF in ${LNLIST[@]}; do
		if [[ ! -L "$CHUNKS/$LNF" ]]; then
  			rm -rf "$CHUNKS/$LNF"
		fi
		ln -s "$CD/$LNF" $CHUNKS
	done
done
cd $CWDIR

## This is the script you use to restart the mine/sync process
$FINALSCRIPT
