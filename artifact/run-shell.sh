#!/usr/bin/env bash

MAINDIR="$(realpath "$(dirname "$0")")"

docker load --input "$MAINDIR"/docker-image.tar

docker run --rm -it -v "$MAINDIR"/code:/code -w /code makam-icfp2018-artifact bash
