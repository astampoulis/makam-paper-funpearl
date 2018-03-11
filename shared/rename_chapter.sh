#!/usr/bin/env bash

set -e

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <from> <to>"
  exit 1
fi

FROM=$1
TO=$2

git mv makamcode/$1.md makamcode/$2.md
sed -i -e 's/$1/$2/g' makamcode/*.md main.tex

