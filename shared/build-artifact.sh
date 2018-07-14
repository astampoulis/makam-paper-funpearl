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

pandoc README.md -o README.txt ;
cp README.md code/ArtifactOverview.md ;

rm -f docker-image.tar;

docker rmi -f makam-icfp2018-artifact || true ;

docker build --tag makam-icfp2018-artifact .;
docker save --output docker-image.tar makam-icfp2018-artifact ;
docker rmi makam-icfp2018-artifact ;

cd ../ ;
rm -f makam-funpearl-artifact.zip ;
tar --transform='s/^artifact/makam-funpearl-artifact/' -cvf makam-funpearl-artifact.tar artifact ;
mkdir -p tmp ;
rm -rf tmp/makam-funpearl-artifact ;
tar xf makam-funpearl-artifact.tar -C tmp/ ;
(cd tmp; zip makam-funpearl-artifact.zip $(tar tf ../makam-funpearl-artifact.tar) ) ;

mv tmp/makam-funpearl-artifact.zip .;
rm makam-funpearl-artifact.tar

)
