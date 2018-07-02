# In which our readers we get a premonition of things to come

\identNormal

*Chapter 3* serves as a tutorial to \lamprolog/Makam, showing the basic usage of the language to
encode the static and dynamic semantics of the simply typed lambda calculus. *Chapter 4* explores
the question of how to implement multiple-variable binding, culminating in a reusable polymorphic
datatype. *Chapters 5 and 6* present a novel account of how GADTs are directly supported in
\lamprolog thanks to the presence of ad-hoc polymorphism and showcase their use for accurate
encodings of mutually recursive definitions and pattern matching.  *Chapter 7* describes a novel way
to define operations by structural recursion in \lamprolog/Makam while only giving the essential
cases, motivating them through the example of encoding a simple conversion rule. The following
chapters make use of the presented features to implement polymorphism and algebraic datatypes
(*Chapter 8*), heterogeneous staging constructs with contextual typing (*Chapter 9*) and
Hindley-Milner type generalization (*Chapter 10*). We then summarize and compare to related work.

We encourage readers to skim through the paper as a first pass, focusing on the
\highlightedtext{highlighted code}. These highlights provide a rough picture
of the Makam code needed to implement a typechecker for a small ML-like
language, along with a few key definitions from the standard library.

\identDialog
