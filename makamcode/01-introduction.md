# Where our heroes set out on a road to prototype a type system

\hero{HAGOP (Student)} (...) So yes, I think my next step should be writing a toy implementation of the
type system we have in mind, so that we can try out some examples and see what works
and what does not.

\hero{ROZA (Advisor)} Definitely -- trying out examples will help you refine your ideas, too.

STUDENT. Let's see, though; we have an ML core, dependently typed constructs, and
contextual types like in \citet{nanevski2008contextual}... I guess I will need a few
months?

ADVISOR. That sounds like a lot. Why don't you use some kind of metalanguage to implement
the prototype?

STUDENT. You mean a tool like Racket/PLT Redex \citep{tobin2011languages,felleisen2009semantics},
the K Framework \citep{rosu2010overview,ellison2009rewriting}, Spoofax \citep{kats2010spoofax}, or
CRSX \citep{rose2011crsx}?

ADVISOR. Yes, all of those should be good choices. I was thinking though that we could
use higher-order logic programming... it's a formalism that is well-suited to what we want to do,
since we will need all sorts of different binding constructs, and the type system we are thinking
about is quite advanced.

STUDENT. Oh, so you mean λProlog \citep{miller1988overview} or LF \citep{pfenning1999system}.

ADVISOR. Yes. Actually, a few years back a friend of mine worked on this new implementation of λProlog
just for this purpose -- rapid prototyping of languages. It's called Makam. It should be
able to handle what we have in mind nicely, and we should not need to spend more than a few hours on it!

STUDENT. Sounds great! Anything I can read up on Makam then?

ADVISOR. Not much, unfortunately... But I know the language and its standard library quite well, so
let's work on this together, it'll be fun. I'll show you how things work along the way!

\begin{scenecomment}
(Our heroes install Makam from --elided for blind reviewing-- and figure out how to run the REPL.)
\end{scenecomment}
