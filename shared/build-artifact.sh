#!/usr/bin/env bash

set -eu

TOPDIR=$(git rev-parse --show-toplevel)

(cd $TOPDIR/artifact;

rm -rf code/justcode;
rm -rf code/literate;
rm -rf code/scripts;

cp -R ../anonsupp/justcode code;
cp -R ../anonsupp/literate code;

mkdir code/scripts/;
cp ../shared/extract-code.sh code/scripts/;
cp ../shared/generate-isolated-makam.awk code/scripts/;

cp README.md code/ArtifactOverview.md ;

rm -f docker-image.tar;

docker rmi -f makam-icfp2018-artifact || true ;

docker build --tag makam-icfp2018-artifact .;
docker save --output docker-image.tar makam-icfp2018-artifact ;
docker rmi makam-icfp2018-artifact ;

cd ../ ;
rm -f artifact.tgz ;
tar --transform='s/^artifact/artifact88/' -cvzf artifact.tgz artifact
)
