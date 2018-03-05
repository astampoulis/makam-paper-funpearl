#!/bin/bash

set -eu

if [[ "$(basename $PWD)" != "anonsupp" ]]; then
  echo "Please use this in the anonsupp directory only."
  exit 1
fi

rm -rf literate
rm -rf justcode

cp -R ../makamcode/ ./literate/
mkdir justcode
cp literate/*.md justcode/

for i in justcode/*.md; do awk -f ../shared/generate-no-comments.awk $i; rm $i; done

rm literate/00-introduction.makam
rm literate/08-summary.makam

mv justcode/01-base-language.makam justcode/02-stlc.makam
mv justcode/02-binding-forms.makam justcode/03-bindmany.makam
mv justcode/03-dependent-binding.makam justcode/04-dbind.makam
mv justcode/04-ml-subset.makam justcode/05-smallml.makam
mv justcode/05-type-synonyms.makam justcode/06-synonyms.makam
mv justcode/06-veriml-light.makam justcode/07-meta.makam
mv justcode/07-hindley-milner.makam justcode/08-typgen.makam

mv literate/01-base-language.md literate/02-stlc.md
mv literate/02-binding-forms.md literate/03-bindmany.md
mv literate/03-dependent-binding.md literate/04-dbind.md
mv literate/04-ml-subset.md literate/05-smallml.md
mv literate/05-type-synonyms.md literate/06-synonyms.md
mv literate/06-veriml-light.md literate/07-meta.md
mv literate/07-hindley-milner.md literate/08-typgen.md

for i in literate/*.md justcode/*.makam; do
  sed -i \
      -e's/01-base-language/02-stlc/' \
      -e's/02-binding-forms/03-bindmany/' \
      -e's/03-dependent-binding/04-dbind/' \
      -e's/04-ml-subset/05-smallml/' \
      -e's/05-type-synonyms/06-synonyms/' \
      -e's/06-veriml-light/07-meta/' \
      -e's/07-hindley-milner/08-typgen/' \
 $i
done
