#!/bin/bash

set -eu

TOPDIR=$(git rev-parse --show-toplevel)

(cd $TOPDIR/anonsupp;

rm -rf literate;
rm -rf justcode;

cp -R ../makamcode/ ./literate/;

rm literate/*introduction.md;
rm literate/*summary.md;
rm literate/*related.md;

$TOPDIR/shared/extract-code.sh literate justcode

)
