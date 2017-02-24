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

if ( ! realpath $INPUT_DIR ); then
  echo "Using pre-generated tex files"
  exit 0;
fi

for INPUT_FILE in $INPUT_DIR/*.md; do

  awk -f impl/scripts/generate-makam.awk $INPUT_FILE

  OUTPUT_FILE="$OUTPUT_DIR/$(basename $INPUT_FILE .md).tex"
  echo "Generating $OUTPUT_FILE from $INPUT_FILE"
  pandoc -S $INPUT_FILE -o $OUTPUT_FILE
  sed -i \
      -e 's/λ/\\ensuremath{\\lambda}/g' \
      -e 's/ω/\\ensuremath{\\omega}/g' \
      -e 's/-\\textgreater{}/\\ensuremath{\\to}/g' \
      -e 's/->/\\ensuremath{\\to}/g' \
      -e 's/=\\textgreater{}/\\ensuremath{\\Rightarrow}/g' \
      -e 's/=>/\\ensuremath{\\Rightarrow}/g' \
      $OUTPUT_FILE

done
