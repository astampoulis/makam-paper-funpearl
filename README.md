# Makam Functional Pearl paper (ICFP'18)

[![CircleCI](https://circleci.com/gh/astampoulis/makam-paper-funpearl.svg?style=svg)](https://circleci.com/gh/astampoulis/makam-paper-funpearl)

Source code for "Prototyping a Functional Language using Higher-Order Logic Programming:
A Functional Pearl on learning the ways of λProlog/Makam", by Antonis Stampoulis and Adam
Chlipala, to appear in the ICFP 2018 issue of PACMPL.

## Build instructions

Our build is Dockerized, so you will need a Docker installation.

To build the paper:

- `make docker-build`

Alternatively, you will need:

- a TexLive installation
- Pandoc
- Node.js

To build the artifact:

- `make artifact`

To build and run the presentation:

- `make docker-slides-offline`
- `make run-slides-offline`
- Visit http://localhost:8000/ in your browser

## Running the code and the tests

Please follow instructions for running the artifact in `artifact/README.md`.
