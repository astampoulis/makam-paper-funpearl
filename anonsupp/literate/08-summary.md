# Where our heroes summarize what they've done and our story concludes before the credits start rolling

STUDENT. I feel like we've done a lot here. And, some of the things we did I don't think
I've seen in the literature before, but then again, it's not clear to me what's
Makam-specific and what isn't. In any case, I think a lot of people would find that
quickly prototyping their PL research ideas using this style of higher-order logic
programming is very useful.

ADVISOR. I agree, though it would be hard for somebody to publish a paper on this. Some of
it is novel, some of it is folklore, some of it, we just did in a pleasant way; and we
did also use a couple of not-so-pleasant hacks. But let's make a list of what's what.

\vspace{-0.5em}
- We defined HOAS encodings of complicated binding forms, including mutually recursive
  definitions and patterns, while only having explicit support in our metalanguage for
  single-variable binding. These encodings are novel, as far as I know. We made use of
  GADTs for them, together with ad-hoc polymorphism, which seems to be a feature specific
  to the Makam implementation of λProlog. We also depended on a technicality for defining
  an essential predicate\footnote{\texttt{assumemany} uses what is technically referred to
  as a strong-hereditary Harrop formula, whereas Teyjus only supports weak-hereditary
  Harrop formulas \citep{nadathur1999system}.}. As a result, we have not been able to
  replicate these in the standard λProlog/Teyjus implementation
  \citep{nadathur1999system}, though all the features we need are part of the original
  λProlog language design \citep{miller1988overview}.

- We defined a generic predicate to perform structural recursion using a very concise
  definition. It allows us to define structurally recursive predicates that only explicitly
  list out the important cases, in what we believe is a novel encoding for the λProlog
  setting. Any new definitions, such as constructors or datatypes we introduce later, do
  not need any special provision to be covered by the same predicates. They depend on a
  number of reflective predicates, which are available in other Prolog dialects; however,
  we are not aware of a published example that makes use of them in the λProlog
  setting. These predicates are used to reflect on the structure of Makam terms, and to
  get the list of local assumptions; for the most part, their use is limited to predicates
  that would be part of the standard library, not in user code.

- The above encodings are reusable and can be made part of the Makam standard library. As
  a result, we were able to develop the type checker for quite an advanced type system, in
  very few lines of code specific to it, all the while allowing for the parts of terms and
  types that can be determined from the context to be left implicit. Our development
  includes mutually recursive definitions, polymorphism, polymorphic datatypes,
  pattern-matching, a conversion rule, Hindley-Milner type generalization, constructs for
  dependent types over a separately specified language of dependent indices, and an
  example of such indices that use contextually typed open terms of the simply typed
  lambda calculus.  We are not aware of another metalinguistic framework that allows this
  level of expressivity and has been used to encode such type-system features.

- We have also shown that higher-order logic programming allows not just meta-level
  functions to be reused for encoding object-level binding; there are also cases where
  meta-level unification can also be reused to encode certain object-level features:
  matching a pattern against a scrutinee and doing type generalization as in Algorithm W.

STUDENT. Well, that was very interesting; thank you for working with me on this!

ADVISOR. I enjoyed this, too. Say, if you want to relax, there's a new staging of the classic play by \citet{fischer2010play} downtown -- I saw it yesterday, and it is really good!

STUDENT. That's a great idea, one of my favorites. I wish there were more plays like it.... Well, good night, and see you on Monday!
