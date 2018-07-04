# Makam Functional Pearl paper (ICFP'18)

Source code for "Prototyping a Functional Language using Higher-Order Logic Programming:
A Functional Pearl on learning the ways of λProlog/Makam", by Antonis Stampoulis and Adam
Chlipala, to appear in the ICFP 2018 issue of PACMPL.

## Build instructions

Our build is Dockerized, so you will need a Docker installation.

To build the paper:

- `make docker-build`

Alternatively, you will need a native PanDoc and a TeXLive installation.

To build the artifact:

- `make artifact`

## Running the code and the tests

Please follow instructions for running the artifact in `artifact/README.md`.
