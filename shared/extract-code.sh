#!/bin/bash

set -e

if [ "x$1" == "x" ]; then echo "usage: $0 <markdown-directory> <makamcode-directory>"; exit 1; fi
if [ "x$2" == "x" ]; then echo "usage: $0 <markdown-directory> <makamcode-directory>"; exit 1; fi

mkdir -p $2

cp $1/*.md $2/

for i in $(ls $2/*.md | sort); do
  rm -f $(echo $i | sed -e 's/md$/makam/' -)
  sed -i -e 's/\.md"/"/' $i;
  awk -f $(dirname $(realpath $0))/generate-isolated-makam.awk $i; rm $i;
done
