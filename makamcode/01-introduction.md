# In which our heroes set out on a road to prototype a type system

\hero{HAGOP (Student)} (...) So yes, I think my next step should be writing a toy implementation of the
type system we have in mind, so that we can try out some examples and see what works
and what does not.

\hero{ROZA (Advisor)} Definitely -- trying out examples will help you refine your ideas, too.

STUDENT. Let's see, though; we have the simply typed λ-calculus, some ML core features, a staging
construct, and contextual types like in \citet{nanevski2008contextual}... I guess I will need a few
weeks?

ADVISOR. That sounds like a lot. Why don't you use some kind of metalanguage to implement
the prototype?

STUDENT. You mean a tool like Racket \citep{racket-manifesto}, PLT Redex \citep{felleisen2009semantics},
the K Framework \citep{k-framework-main-reference} or Spoofax \citep{spoofax-main-reference}?

ADVISOR. Yes, all of those should be good choices. I was thinking though that we could
use higher-order logic programming... it's a formalism that is well-suited to what we want to do,
since we will need all sorts of different binding constructs, and the type system we are thinking
about is quite advanced.

STUDENT. Oh, so you mean λProlog \citep{lambdaprolog-main-reference} or LF \citep{lf-main-reference}.

ADVISOR. Yes. Actually, a few years back a friend of mine worked on this new implementation of λProlog
just for this purpose -- rapid prototyping of languages. It's called Makam. It should be
able to handle our MetaML-like language nicely, and we should not need to spend more than a few hours on it!

STUDENT. Sounds great! Anything I can read up on Makam then?

ADVISOR. Not much, unfortunately... But I know the language and its standard library quite well, so
let's work on this together; it'll be fun. I'll tell you all the details along the way too -- I know how
you always want to understand things in depth!

\begin{scenecomment}
(Our heroes install Makam from
\href{https://github.com/astampoulis/makam}{\texttt{https://github.com/astampoulis/makam}}
and figure out how to run the REPL.)
\end{scenecomment}
