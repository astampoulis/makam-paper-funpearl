# Where our heroes set on a road to prototype a type system

HAGOP. (...) So yes, I think my next step should be writing a toy implementation of the
type system we have in mind, so that we can try out some examples and see what works
and what does not.

ROZA. Definitely -- trying out examples will help us refine our ideas too.

HAGOP. Let's see though, we have an ML core, dependently typed constructs, and
contextual types like in \citet{nanevski2008contextual}... I guess I will need a few
months?

ROZA. That sounds like a lot. Why don't you use some kind of metalanguage to implement
the prototype?

HAGOP. You mean a tool like PLT Redex \citep{felleisen2009semantics}, the K
Framework \citep{rosu2010overview,ellison2009rewriting}, Spoofax \citep{kats2010spoofax}, 
or CRSX \citep{rose2011crsx}?

ROZA. Sure, all fine choices. Though I do not think these frameworks have been used to
implement a type system as advanced as the one we have in mind, or can handle all the
binding constructs we will need... I was actually thinking we should use higher-order
logic programming.

HAGOP. Oh, so \lamprolog \citep{miller1988overview} or LF \citep{pfenning1999system}.

ROZA. Yes. Actually a few years back I worked on this new implementation of \lamprolog
just for this purpose -- rapid prototyping of languages. It's called Makam. It should be
able to handle what we have in mind, and we won't need more than a few hours.

HAGOP. Sounds great! Anything I can read up on it?

ROZA. Not much unfortunately... Let's just work on this together, it'll be fun.

(Our heroes install Makam from
\if@ACM@anonymous{\url{http://github.com/astampoulis/makam}}\else{\em--elided for blind
reviewing--}\fi\xspace
and figure out how to run the REPL.)
