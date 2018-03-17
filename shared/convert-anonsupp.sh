#!/bin/bash

set -eu

TOPDIR=$(git rev-parse --show-toplevel)

(cd $TOPDIR/anonsupp;

rm -rf literate;
rm -rf justcode;

cp -R ../makamcode/ ./literate/;
mkdir justcode;

rm literate/*introduction.md;
rm literate/*summary.md;
rm literate/*related.md;

cp literate/*.md justcode/;

for i in justcode/*.md; do
  sed -i -e 's/\.md"/"/' $i;
  awk -f ../shared/generate-no-comments.awk $i; rm $i;
done)
