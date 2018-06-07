# In which our heroes are nowhere to be found, lost in a sea of references to related work

\identNormal

<!--
\hero{\bf Higher-order logic programming} Most of the development we present should be easy
to transcribe to other implementations of \lamprolog like Teyjus \citep{teyjus-main-reference}
and ELPI \citep{elpi-main-reference}. Also, existing work in the same area
has considered aspects of the developments we present. Specifically:

- the binding constructions we present like multiple binding, patterns
and contextual terms work in both of these implementations. The
definition of `assumemany` is not supported in Teyjus, as it rests
outside the fragment of hereditary Harrop formulas and breaks the
logical properties of the language \citep{assumemany-issue}; however, the few uses of it that
we make can be inlined instead. Still, we have noticed a few issues
with the type checker of ELPI; especially predicates that make use of
ad-hoc polymorphism like `vmap` and `vopenmany` might not offer the
same type safety as they do in Makam or Teyjus.
- we have made sparing use of the runtime aspect of ad-hoc
polymorphism, which is not supported in ELPI; one such example is the
definition of `structural_recursion` and the `getunif` predicate.
- while standard metalogical predicates like `refl.isunif` are available
under other names in most \lamprolog implementations, others, like `refl.assume_get`
are not directly supported. Still, we believe that they should be possible to add.
- to the best of our knowledge, our use of ad-hoc polymorphism to encode GADTs
is novel in the setting of \lamprolog, as is our definition of generic predicates like
structural recursion
- logical alternatives to various issues that we discuss are available. For example,
the `typeq` predicate could be implemented as first discussed based on tabling \citep{tabling-main-reference}. Also, mode declarations as found in ELPI and Twelf \citep{twelf-main-reference} can be used instead of uses of `refl.isunif`, as done in
our use of `typedef`. These features are not supported at present in Makam and are left for future work.
- existing work that has considered the problem of ML type generalization
in the \lamprolog setting can be found in \citet{typgen-lamprolog-1} and \citet{typgen-lamprolog-2}.
- we make heavy use of polymorphic datatypes such as `list` and `bindmany`, which we believe is
essential for achieving the conciseness that the use case of rapid prototyping demands. These are not supported in higher-order logic programming systems
based on LF \citep{lf-main-reference} such as Twelf \citep{twelf-main-reference} and Beluga \citep{beluga-main-reference}, because they break the
adequacy of encodings in that case. Specializing such datatypes to their uses should be enough to
transcribe our examples that do not make use of meta-logical reflective predicates.
-->

The **Racket programming language** was designed to support creation of new
programming languages \citep{racket-manifesto} and has been used to implement a very wide variety of DSLs
serving specific purposes,
including typed languages such as Typed Racket by \citet{typed-racket-main-reference}. We believe
that one of the key characteristics of the Racket approach to language implementation is the
ability to treat code as data. Makam is largely inspired by this approach and follows along
the same lines; this is not demonstrated in the present work to a large extent, save for the
use of `refl.assume_get`, which turns code (the local assumptions for a predicate) into data
(a reified list of the assumptions). Still, we believe the presence of first-class binding
support in the form of higher-order abstract syntax makes the \lamprolog setting significantly
different from Racket.

The recent development of a methodology for developing **type systems as macros** by
\citet{racket-type-systems-as-macros} is a great validation of the Racket approach and is especially
relevant to our use case, as it has been used to encode type systems similar to ML. The integration
that this methodology provides with the rest of the Racket ecosystem offers a number of advantages,
as does the \rulename{Turnstile} DSL for writing typing rules close to the pen-and-paper
versions. We do believe that the higher-order logic programming setting allows for more expressivity
and genericity -- for example, we have used the same techniques to define not only typing rules but
evaluation rules as well, and it is not immediately clear to us whether examples such as our MetaML
fragment would be as easy to implement in \rulename{Turnstile}. We are exploring an approach similar
to \rulename{Turnstile} to implement a higher-level surface language for writing typing rules using
Makam itself.

Evaluation rules can be implemented using another DSL of the Racket ecosystem, namely **PLT Redex**
\citep{felleisen2009semantics}. We believe that staying within the same framework for both aspects
offers other advantages, especially for encoding languages where the two aspects are more linked,
such as dependently typed languages with the conversion rule. We give one small example of that in
the form of the type synonyms example. We also find that the presence of first-class substitution
support and the support for structural recursion in Makam offers advantages over PLT Redex.

The **Spoofax language workbench** \citep{spoofax-main-reference} offers a series of DSLs for
implementing different aspects of a language, such as parsing, binding, typing and dynamic
semantics. We have found that some of these DSLs have restrictions that would make the
implementation of type systems similar to the ones we demonstrate in the present work
challenging. Our intention with the design of Makam as a language prototyping tool is for it to be a
single expressive core, where all different aspects of a language can be implemented. The **K
Framework** \citep{k-framework-main-reference} is a semantics framework based on rewriting and has
been used to implement the dynamic semantics of a wide variety of languages.  It has also been shown
to be effective for the implementation of type systems \citep{k-framework-type-systems}, treating
them as abstract machines that compute types rather than values. The recent addition of a builtin
unification procedure has made this approach significantly more effective, allowing the definition
of ML type inference; however, the fact that \lamprolog supports higher-order unification as well
renders it applicable in further situations such as dependently typed systems. As future work, we
are exploring the design of a core calculus to aid in the bootstrapping of a language such as Makam,
and we believe that a connection with the rewriting-logic core of the K framework will prove
beneficial in this endeavor.