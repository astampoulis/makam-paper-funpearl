# Getting started

This artifact can be used to run the Makam code that is contained in
the paper and to experiment with changes and additional queries.

We include a Makam installation as a Docker image, along with the
Makam code fragments from the paper. As the paper is a literate
development, we include the literate code of the paper itself as well.

To use this artifact, you will need to have Docker installed. Please
follow instructions for your system from:

<https://www.docker.com/community-edition>

(At the time of writing, the latest Docker version is 18.03.1-ce-0.)

The artifact is a gzipped tar file, extract it and switch to its main
directory using:

    tar xvzf makam-funpearl-artifact.tgz
    cd makam-funpearl-artifact

You can use the `run-makam.sh` script to load the Docker image and
start a Docker container running the Makam REPL:

    ./run-makam.sh

The REPL will give brief usage instructions on startup.  Each chapter
of the paper corresponds to a single Makam file, stored in the
`code/justcode/` directory within the artifact. To load a chapter
within the Makam REPL, issue, for example:

    %use "04-bindmany".

Note the dot at the end! Makam statements end either with a dot (`.`) or
a question-mark (`?`).

The corresponding file ends in a `.makam` extension, which you do not
need to include. For the list of chapter files, see "Step-by-Step
instructions" below. This will also load all dependencies and run all
the contained queries. Note that all examples here should execute
within a few seconds.

Each query shown in the paper (and some additional queries that are
included in the code) is accompanied by a test case that captures
the expected result of the query. To run the tests in a chapter you
just loaded, issue the following query:

    run_tests [tests] ?

To run all tests within the paper, issue:

    %use "10-typgen".
    run_tests X ?

(The file `10-typgen` corresponds to the last chapter that contains code,
and the line following that runs all tests loaded up to that point.)

In the REPL, you can issue your own queries, for example:

    typeof (lammany (bind (fun x => bind (fun y => body (tuple [y, x]))))) T ?

You can also add new types, constructors, and rules within the same
REPL, using the same syntax that is shown in the paper.

For larger additions or changes to the existing code, you can edit the
files in `code/justcode/` directly. The `code/` directory of the
artifact is mounted within the Docker container — so, you can
make changes to the Makam code in `code/justcode/` in your host
environment (using your favorite editor etc.) and these will be
reflected within the Docker container. To reload a chapter after you
have made changes, issue, for example:

    %usenew "04-bindmany".

To exit the Makam REPL, issue an EOF (usually Ctrl-D).

The artifact also contains the literate code that the paper is
generated from in the `code/literate/` directory, as Markdown files
with the `.md` extension. The Makam code in `code/justcode/` is
directly extracted from these literate files, by isolating the code
blocks that are marked with `makam` or `makam-stdlib`, using the
`convert-literate` script that is contained in the artifact (more
details in the next section).  Alternatively, you can load the
Markdown files directly within the Makam REPL:

    %use "literate/04-bindmany.md".

The Makam REPL does not support line editing. The Docker image
includes `rlwrap` that which should enable line editing in most
environments. To use that, you have to use the `run-shell.sh` script
in your host system, which will create a Docker container that gives
you access to a shell (instead of dropping you directly onto the Makam
REPL). Then you can run the Makam REPL with `rlwrap makam`:

    ./run-shell.sh
    rlwrap makam

If for any reason volume mounting does not work in your system (if
that's the case, some of the things above won't work, e.g. you do not
get the usage message when you start up the Makam REPL), the Makam
code is also available within the Docker image, in the `/static`
directory. In order to use those, use the `run-shell.sh` script as above,
and switch to the `/static` directory before starting the Makam
REPL and following the instructions above:

    ./run-shell.sh
    cd /static
    makam

In this case, you will have to edit files within the Docker container.
The container already contains `vi`; you can install other editors using
`apk` since this is an Alpine-based image.

# Step-by-Step Instructions

In this section we provide more details into how to evaluate particular
aspects of the artifact.

## Connection to the paper

As mentioned above, each chapter of the paper is generated from a
literate Markdown file that contains embedded Makam code. Though the
literate files can be inspected and loaded into the Makam REPL directly,
we find that isolating the code from each chapter makes the code easier
to follow for someone comfortable with the material.

The list of files corresponding to each chapter is:

    code/justcode/03-stlc.makam
    code/justcode/04-bindmany.makam
    code/justcode/05-gadts.makam
    code/justcode/06-patterns.makam
    code/justcode/07-structural.makam
    code/justcode/08-miniml.makam
    code/justcode/09-metaml.makam
    code/justcode/10-typgen.makam

We also include one file, `06-removed-pattern-eval`, that is not part
of the paper. This contains the evaluation rules for the pattern
matching extension (Chapter 6); we believe they should not have any
surprises for somebody who has followed the paper up to that point,
so we elide them for space reasons. The rules contained in this file
are used in subsequent chapters in some cases of `eval` queries.

One way we would recommend evaluating each chapter is to read through
the corresponding isolated Makam code in these files, load the file
into the Makam REPL as above, and run the corresponding tests with
`run_tests [tests] ?`.  Each query corresponds to a single test: the
notation with `>>` that we use generates a test case that checks
whether the query yields the given result — success or failure, and a
particular instantiation of the unification variables.

For example, after loading `03-stlc`, this is an example of a
successful query, along with the corresponding expected result:

    typeof (lam _ (fun x => x)) T ?
    >> Yes:
    >> T := arrow T1 T1.

Of course, the `>>` notation after a query is optional; if it's
omitted, no test case is generated.

The results of each query can also be manually inspected. In that
case the actual printout from the Makam REPL might differ in terms of
the names of the unification variables and lacks syntactic sugar for
lists and tuples.

## Working with the literate code

Generating the isolated code files from the literate files is done as
follows:

- Any code blocks that are marked with `makam` make it directly to the
corresponding `.makam` file of a chapter.

- Some chapters also include code that is assumed to be part of the
Makam standard library. To simplify our presentation, we diverge slightly
from the definitions of the actual Makam standard library in a few
cases. These code blocks are marked as `makam-stdlib` and are extracted
into the `code/justcode/00-adapted-stdlib.makam` file.

- For presentation purposes, the paper diverges in some cases from the
exact order of the Makam code. As a result, we have some "hidden"
Makam code blocks that are not part of the paper, which are enclosed
within HTML comments in the corresponding literate files.

- We also use hidden blocks for additional examples and a few extras,
like evaluation of programs.

The literate files can be loaded directly into the Makam REPL, in which
case the code blocks marked with `makam` or `makam-stdlib` will be
executed.

We also include the script `convert-literate` that converts from the
literate files into the isolated code files. To run this if you have
made changes to the `code/literate/` files and would like to see the
corresponding code in `code/justcode/`, use the `run-shell.sh` script
to get a bash shell in the Docker container:

    ./run-shell.sh
    ./convert-literate

(Warning: this will override any changes you have made to the files
in `justcode` directly!)

## Debugging facilities

If some queries do not behave in the way you expect (e.g. after changes
to rules or adding new rules), you can use Makam's debugging facilities
to understand more about how queries are evaluated. Makam offers two
predicates to help with that:

    trace : A -> prop -> prop.
    debug : prop -> prop.

`trace P Q` can be used to keep track of when we enter/exit into an
intermediate goal that involves a particular predicate `P`, while
trying to find a solution for proposition `Q`.  For example, to trace
the `typeof` predicate for a particular query we can use:

    trace typeof (typeof (lammany (bind (fun x => bind (fun y => body (tuple [y, x]))))) T) ?

`debug Q` can be used to keep track of *all* of the intermediate goals —
it's similar to tracing all of the predicates:

    debug (typeof (lammany (bind (fun x => bind (fun y => body (tuple [y, x]))))) T) ?

Of course, printf-style debugging is also possible — you can use the
`print` predicate to print an arbitrary Makam term or `print_string`
to print a string as is.

## Makam standard library

Outside the code contained in the paper, we make very little use of
the actual Makam standard library: we use definitions of lists and
tuples, as well as the testing framework that we use for validating
the results of queries. The standard library itself is contained
within the Docker container, if you navigate to `/makam/stdlib`:

    ./run-shell.sh
    cd /makam/stdlib
    cat init.makam

# Additional information

## Makam and paper source

Makam is open-source software licensed under the GPL, hosted in the GitHub
repository:

<https://github.com/astampoulis/makam>

This artifact bundles Makam version 0.7.12, accessible through the URL:

<https://github.com/astampoulis/makam/releases/tag/v0.7.12>

The source code of the paper, along with CircleCI integration which builds the
paper and this artifact, are available at:

<https://github.com/astampoulis/makam-paper-funpearl>
