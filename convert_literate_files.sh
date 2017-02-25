#!/bin/bash

function usage() {
  echo "Usage: $0 <input-dir> <output-dir>"
  exit 1
}

if [[ "$#" -lt 2 ]]; then
  usage
fi

INPUT_DIR=$1
OUTPUT_DIR=$2

for INPUT_FILE in $INPUT_DIR/*.md; do

  awk -f shared/generate-makam.awk $INPUT_FILE

  OUTPUT_FILE="$OUTPUT_DIR/$(basename $INPUT_FILE .md).tex"
  echo "Generating $OUTPUT_FILE from $INPUT_FILE"
  pandoc -S $INPUT_FILE -o $OUTPUT_FILE
  sed -r -i \
      -e 's/([α-ω]+)/\\foreignlanguage{greek}{\1}/g' \
      -e 's/-\\textgreater\{\}/\\ensuremath{\\to}/g' \
      -e 's/->/\\ensuremath{\\to}/g' \
      -e 's/=\\textgreater\{\}/\\ensuremath{\\Rightarrow}/g' \
      -e 's/=>/\\ensuremath{\\Rightarrow}/g' \
      -e 's/^([A-Z]+)\./\\hero\1{}/g' \
      $OUTPUT_FILE

done
