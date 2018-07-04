#!/usr/bin/env bash

set -eu

TOPDIR=$(realpath $(dirname $0))/..

(cd $TOPDIR;

rm -f justcode/*.makam;

shared/extract-code.sh makamcode justcode;

ls justcode)
