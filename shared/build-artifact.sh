#!/usr/bin/env bash

set -eu

TOPDIR=$(git rev-parse --show-toplevel)

(cd $TOPDIR/artifact;

rm -rf code/justcode;
rm -rf code/literate;

cp -R ../anonsupp/justcode code;
cp -R ../anonsupp/literate code;

rm -f docker-image.tar;

docker rmi -f makam-icfp2018-artifact || true ;

docker build --tag makam-icfp2018-artifact .;
docker save --output docker-image.tar makam-icfp2018-artifact ;
docker rmi makam-icfp2018-artifact
)
