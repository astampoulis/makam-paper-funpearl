#!/usr/bin/env bash

set -e

for i in makamcode/*.md; do
  TESTSUITE=$(grep "%testsuite" $i | sed -r -e 's/^.*%testsuite ([^\.]+).*$/\1/' -)
  [[ ! -z $TESTSUITE ]] && echo "run_tests ($TESTSUITE: testsuite) ?" | makam $i -
  true
done
