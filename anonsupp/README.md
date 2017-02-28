# Supplementary material

This is the anonymized supplementary material for the paper:

*Prototyping a Functional Language using Higher-Order Logic Programming*
(A Functional Pearl on learning the ways of λProlog/Makam)

We provide a Linux/x86_64 binary for the Makam REPL, which has been
anonymized.  This should be able to run in a modern Linux
distribution, and should also be able to be run in a base Ubuntu image
through [Docker](https://www.docker.com/):

    docker run --rm -it $(pwd):/code -w /code ubuntu

We also provide the literate developments in the `literate` folder, in
both Makam and Markdown formats. The `.makam` files can be loaded
directly within the Makam REPL. Any queries contained within the files
will run and their results will be displayed. Further queries can be
made through the REPL; new definitions can also be made in the REPL
directly as well. Studying the files side-by-side with the REPL is
recommended.

## Instructions for using the REPL

1. Start the REPL with
   `./makam`.
2. To load one of the developments, do
   `%use "02-stlc".`
3. Files that have been already loaded won't get loaded again with `%use`.
   If you make changes to a file and want to load it anew, you can use
   `%usenew "02-stlc".`
   Note that this will also load all files dependent on it.

## File structure

`makam-bin` -- Makam binary
`makam` -- Shell script to launch Makam
`init.makam` -- Initialization file
`stdlib/` -- Contains the standard library of Makam. We make limited
  use of it in the paper development: `list` predicates, some basic
  types like `option`, the `generic.fold` predicate, and `dyn.call`.
`literate/` -- Directory containing the literate Markdown files of the
  paper, together with Makam files generated from them. To load files
  from this directory in Makam, do `%use "literate/02-stlc".`
`justcode/` -- Directory containing just the code part of the literate
  developments. These are generated from the Markdown files too, without
  adding comments, and are thus easier to read for the code part, and they
  are more amenable to modifications. The `justcode` directory
  is included in the Makam search path, so loading files with `%use` will
  make use of the files in this directory without specifying it.

## Notes

- We have included a few more examples than shown in the paper.
- The replies to queries from the Makam REPL should match what's in the
  paper, up to alpha-renaming of unification and bound variables, and
  a certain lack of pretty-printing (e.g. for lists). Proper naming for
  unification variables is hard :). We have given them more intuitive
  names in the paper for presentation purposes.
- Please do not redistribute this binary. There is an open-source Makam
  repository, though searching for it would defeat the anonymization.
  
## Thank you

Thanks for looking at this!
