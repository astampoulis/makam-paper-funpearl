#!/usr/bin/env bash

docker load --input docker-image.tar

docker run --rm -it -v $(pwd)/code:/code -w /code makam-icfp2018-artifact makam $*
