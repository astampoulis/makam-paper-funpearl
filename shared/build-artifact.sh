#!/usr/bin/env bash

set -eu

TOPDIR=$(git rev-parse --show-toplevel)

(cd $TOPDIR/artifact;

rm -rf code/justcode;
rm -rf code/literate;
rm -rf code/scripts;

cp -R ../makamcode/ ./code/literate/;

rm code/literate/*introduction.md;
rm code/literate/*summary.md;
rm code/literate/*related.md;

$TOPDIR/shared/extract-code.sh code/literate code/justcode;

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
rm -f makam-funpearl-artifact.tgz ;
tar --transform='s/^artifact/makam-funpearl-artifact/' -cvzf makam-funpearl-artifact.tgz artifact
)
