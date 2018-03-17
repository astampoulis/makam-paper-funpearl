# Supplementary material

This is the anonymized supplementary material for the paper:

*Prototyping a Functional Language using Higher-Order Logic Programming*
(A Functional Pearl on learning the ways of λProlog/Makam)

We provide Linux/x86_64 and MacOS X binaries for the Makam REPL.
The former should be able to run in a modern Linux
distribution, and should also be able to be run in a base Ubuntu image
through [Docker](https://www.docker.com/):

    docker run --rm -it $(pwd):/code -w /code ubuntu

In MacOS, please use the `makam-macos` script instead of `makam` below.

We also provide the literate developments in the `literate` folder in
Markdown formats, as well as versions of the developments were only
the code is present, as `.makam` files in the `justcode/` directory.
Both kinds of files can be loaded directly within the Makam REPL. Any
queries contained within the files will run and their results will be
displayed. Further queries can be made through the REPL; new
definitions can also be made in the REPL directly as well. Studying
the files side-by-side with the REPL is recommended.

## Instructions for using the REPL

1. Start the REPL with
   `./makam`.
2. To load one of the developments, do
   `%use "03-stlc.md".`
3. Files that have been already loaded won't get loaded again with `%use`.
   If you make changes to a file and want to load it anew, you can use
   `%usenew "03-stlc.md".`
   Note that this will also load all files dependent on it.
4. Each file comes with a number of tests, in the form of queries that
   have expected results, which can be run with a command of the form:
   `./makam --run-tests 03-stlc.md`

## File structure

`makam-bin` -- Makam binary
`makam` -- Shell script to launch Makam
`init.makam` -- Initialization file
`stdlib/` -- Contains the standard library of Makam. We make limited
  use of it in the paper development, because our definitions of
  `bindmany`, `structural_recursion` differ slightly from what is
  in the standard library. (They are redefined within the literate
  developments.) The main parts of the standard library we use are:
  `list` and `list` predicates and some basic types like `option`.
`literate/` -- Directory containing the literate Markdown files of the
  paper. Makam can read these files and executes all code blocks marked
  as `makam` (skipping `makam-noeval` blocks). To load files
  from this directory in Makam, do `%use "literate/03-stlc.md".`
`justcode/` -- Directory containing just the code part of the literate
  developments. These are generated from the Markdown files too, without
  adding comments, and are thus easier to read for the code part. They
  are also more amenable to modifications.

## Notes

- We have included a few more examples than shown in the paper.
- The replies to queries from the Makam REPL should match what's in the
  paper, up to alpha-renaming of unification and bound variables, and
  a certain lack of pretty-printing (e.g. for lists). Proper naming for
  unification variables is hard :). We have given them more intuitive
  names in the paper for presentation purposes. Still, the `>>` notation
  after queries generates testcases, which are matched properly against
  the results.
- Please do not redistribute this binary. There is an open-source Makam
  repository, as well as an `npm` package for it, though searching for
  these would defeat the anonymization.
  
## Thank you

Thanks for looking at this!
