#!/usr/bin/env bash

gs -sOutputFile=main-bw.pdf -sDEVICE=pdfwrite -sColorConversionStrategy=Gray -dProcessColorModel=/DeviceGray -dCompatibilityLevel=1.4 -dNOPAUSE -dBATCH main.pdf

convert -monitor -density 300 -trim main.pdf -strip -depth 32 -colorspace sRGB -color-matrix '0.0 2.02344 -2.52581 0.0 1.0 0.0 0.0 0.0 1.0' +set profile main-proto.pdf

convert -monitor -density 300 -trim main.pdf -strip -depth 32 -colorspace sRGB -color-matrix '1.0 0.0 0.0 0.494207 0.0 1.24827 0.0 0.0 1.0' +set profile main-deut.pdf

convert -monitor -density 300 -trim main.pdf -strip -depth 32 -colorspace sRGB -color-matrix '1.0 0.0 0.0 0.0 1.0 0.0 -0.395913 0.801109 0.0' +set profile main-trit.pdf
