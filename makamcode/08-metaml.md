# Where our heroes tackle dependencies, contexts, and a new level of meta

<!--
```makam
%use "06-structural.md".
tests: testsuite. %testsuite tests.
```
-->

STUDENT. I'm fairly confident by now that Makam should be able to handle the research idea
we want to try out. Shall we get to it?

ADVISOR. Yes, it is time. So, what we are aiming to do is add a facility for type-safe, heterogeneous meta-programming to our object language, similar to MetaHaskell \citep{mainland2012explicitly}. This way we can manipulate the terms of a *separate* object language in a type-safe manner.

STUDENT. Exactly. We aim for our object language to be a formal logic,
so our language will be similar to Beluga
\citep{beluga-main-reference} or VeriML
\citep{veriml-main-reference}. We'll have to be able to pattern match
over the terms of the object language, so they will be runtime
entities, rather than erasable static entities.... But we don't need
to do all of that; let's just do a basic version for now, and I can do
the rest on my own.

\newcommand\dep[1]{\ensuremath{#1}}
\newcommand\lift[1]{\ensuremath{\langle#1\rangle}}
\newcommand\odash[0]{\ensuremath{\vdash_{\text{o}}}}
\newcommand\wf[0]{\ensuremath{\; \text{wf}}}

ADVISOR. Sounds good. Still, we should use the generic
dependently-typed framework that we have come up with. But before we
get to that, let's agree on some terminology first, because a lot of
words are getting overloaded a lot. Let us call *objects* $o$
any sorts of terms of the object language that we will be manipulating.
And, for a lack of a better word, let us call *classes* $c$ any sort of types
that characterize those objects through a typing relation of the form $\Psi \odash o : c$. It
is unfortunate that these names suggest object-orientation, but this is not the intent.

STUDENT. I see what you are saying. In the language we have in mind, the objects,
as you just defined them, include both terms and types; and as a result, the classes
should be types (characterizing terms) and kinds (characterizing types).
Now, I think the fragment that we should do is this: we should
have dependent functions over the objects, where one object can depend on another one.
We need the dependency so that, for example, we can take an object type `T` as an
argument and return an object term of that exact type `T`.
Dependent products should be similar, but we can skip them for now and just add
a way to return an object as a meta-level value.

ADVISOR. Good idea. We are getting into many levels of meta -- there's the meta-language
we're using, Makam; there's the object language we are encoding, which is now becoming a meta-language
in itself, let's call that Heterogeneous Meta ML Light (HMML?); and there's the
"object-object" language that HMML is manipulating. And let's keep that last one simple: the simply typed lambda calculus (STLC).

STUDENT. Great. Other options for the language of objects could be -- a language
of natural numbers, equality predicates, and equality proofs, which would be quite similar to the Dependent ML formulation of
\citet{licata2005formulation}; or even the full meta-language itself, which would be more
similar to a homogeneous, multi-stage language like MetaML \citep{metaml-main-reference}. But in this case,
our objects will be the types and terms of STLC -- actually, the open terms of STLC.

ADVISOR. It's a plan. So, let's get to it. Should we write some of the system down on paper first?

STUDENT. Yes, that will be necessary. Here are the typing rules for the new constructs in HMML, which depend
on an appropriately defined typing judgment $\Psi \odash o : c$ for objects and a well-formedness judgment
$\Psi \odash c \wf$ for classes. We use $\dep{v}$ for variables standing for objects. 

\vspace{-1.5em}
\begin{mathpar}
\inferrule[Typeof-LamDep]
          {\Gamma; \dep{\Psi}, \; \dep{v} : \dep{c} \vdash e : \tau \\ \dep{\Psi} \odash \dep{c} \; \text{wf}}
          {\Gamma; \dep{\Psi} \vdash \Lambda \dep{v} : \dep{c}.e : \Pi \dep{v} : \dep{c}.\tau}

\inferrule[Typeof-AppDep]
          {\Gamma; \dep{\Psi} \vdash e : \Pi \dep{v} : \dep{c}.\tau \\ \dep{\Psi} \odash \dep{o} : \dep{c}}
          {\Gamma; \dep{\Psi} \vdash e @ \dep{o} : \dep{\text{subst}}(\tau, [\dep{o}/\dep{v}])}

\inferrule[Typeof-LiftDep]
          {\dep{\Psi} \odash \dep{o} : \dep{c}}
          {\Gamma; \dep{\Psi} \vdash \lift{\dep{o}} : \lift{\dep{c}}}
\end{mathpar}

\input{generated/todo}

Let's first add distinguished sorts for objects and classes. Let's also have a distinguished type for *dependent variables*, that is, variables of dependent indices; and a way to substitute such a variable for an object.

```makam
depindex, depclassifier, depvar : type.
depclassify : depindex -> depclassifier -> prop.
depclassify : depvar -> depclassifier -> prop.
depwf : depclassifier -> prop.
depsubst : [A] (depvar -> A) -> depindex -> A -> prop.
```


STUDENT. Right, we might need to check that classifiers are well-formed. And we might need to treat variables specially, so it's good that they're a different type. So, that's why you made substitution a predicate, rather than using the normal HOAS function application `F X` directly, as we have been doing so far. I know that when we add variables that stand for open STLC terms, there will be some extra computation involved to substitute them for an open term, so the normal application won't work as is.

ADVISOR. Exactly; and that extra computation will be necessary in order to maintain type-safety. Hopefully, we won't have to write any unnecessary cases, though! Now, we have a few typing rules to add. I'll use ``$\dep{\cdot}$'' to signify things that have to do with the dependent indices.

STUDENT. Those are very easy to transcribe to Makam.

```makam
lamdep : depclassifier -> (depvar -> term) -> term.
appdep : term -> depindex -> term.
liftdep : depindex -> term. liftdep : depclassifier -> typ.
pidep : depclassifier -> (depvar -> typ) -> typ.
typeof (lamdep C EF) (pidep C TF) :-
  (v:depvar -> depclassify v C -> typeof (EF v) (TF v)), depwf C.
typeof (appdep E I) T' :- typeof E (pidep C TF), depclassify I C, depsubst TF I T'.
typeof (liftdep I) (liftdep C) :- depclassify I C.
```

ADVISOR. Looks nice. Just wanted to say, this framework is quite general. I'll add the
object language in a separate namespace prefix -- we can use `\texttt{\%extend}' for going
into a namespace -- and I'll just copy-paste our STLC code from earlier on.

```
%extend object.
term : type. typ : type. typeof : term -> typ -> prop.
...
%end.
```

<!--
We don't have to copy-paste the code, we can import the previous file into a separate namespace. But let's add natural numbers too.

```makam
%import "02-stlc.md" as object.
%extend object.
onat : typ. ozero : term. osucc : term -> term.
typeof ozero onat.
typeof (osucc N) onat :- typeof N onat.
eval ozero ozero.
eval (osucc E) (osucc V) :- eval E V.
%end.
```
-->

<!-- flipped order in the narrative, we need to declare `wftyp` first.
```makam
%extend object.
wftyp : typ -> prop.
lam : typ -> (term -> term) -> term.
typeof (lam T E) (arrow T T') :-
  (x:term -> typeof x T -> typeof (E x) T'), wftyp T.
%end.
```
-->

STUDENT. Great! I'll make these into dependent indices now, including both types and terms.

```makam
iterm : object.term -> depindex.     ityp : object.typ -> depindex.
ctyp : object.typ -> depclassifier.  cext : depclassifier.
depclassify (iterm E) (ctyp T) :- object.typeof E T.
depclassify (ityp T) cext :- object.wftyp T.
depwf (ctyp T) :- object.wftyp T.
depwf cext.
```

ADVISOR. Right, we'll need to check that types are well-formed, too. Right now, they are all well-formed by construction, but let's prepare for any additions, by setting up a structurally recursive predicate. The `wftyp_cases` predicate will hold the important type-checking cases, and we will have an extra predicate to say whether those cases apply or not for a specific `typ`.

```
%extend object.
wftyp : typ -> prop. wftyp_aux : [A] A -> A -> prop.
wftyp_cases, wftyp_applies : [A] A -> prop.
wftyp T :- wftyp_aux T T.
wftyp_aux T T :- if (wftyp_applies T)
                 then (wftyp_cases T)
                 else (structural_recursion wftyp_aux T T).
%end.
```

<!-- warning: don't redeclare wftyp from above.

```makam
%extend object.
wftyp_aux : [A] A -> A -> prop.
wftyp_cases, wftyp_applies : [A] A -> prop.
wftyp T :- wftyp_aux T T.
wftyp_aux T T :- if (wftyp_applies T)
                 then (wftyp_cases T)
                 else (structural_recursion wftyp_aux T T).
%end.
```

-->

STUDENT. I see -- if a type-checking rule applies, but fails, we don't want to proceed to
also try structural recursion; it would defeat the purpose. Neat trick. I also see that
your structural recursion just needs to do a simple visit and it does not need to produce an
output; hence the repeat of the same `typ` argument. Let's prepare for substitutions, too,
in the same way.

```makam
depsubst_aux, depsubst_cases : [A] depvar -> depindex -> A -> A -> prop.
depsubst_applies : [A] depvar -> A -> prop.
depsubst F I Res :- (v:depvar -> depsubst_aux v I (F v) Res).
depsubst_aux Var Replace Where Res :-
  if (depsubst_applies Var Where)
  then (depsubst_cases Var Replace Where Res)
  else (structural_recursion (depsubst_aux Var Replace) Where Res).
```

ADVISOR. Great! We only have one thing missing: we need to close the loop, being able to refer to a dependent variable from within an object-level term or type. 

STUDENT. I got this.

```makam
%extend object.
varterm : depvar -> term.  vartyp : depvar -> typ.
typeof (varterm V) T :- depclassify V (ctyp T).
wftyp_applies (vartyp V). wftyp_cases (vartyp V) :- depclassify V cext.
%end.
depsubst_applies Var (object.varterm Var).
depsubst_cases Var (iterm Replace) (object.varterm Var) Replace.
depsubst_applies Var (object.vartyp Var).
depsubst_cases Var (ityp Replace)  (object.vartyp Var)  Replace.
```

ADVISOR. This is exciting; let me try it out! I'll do a function that takes an
object-level type and returns the object-level identity function for it.

```makam-noeval
typeof (lamdep cext (fun t =>
         (liftdep (iterm (object.lam (object.vartyp t) (fun x => x)))))) T ?
>> Yes!!!!!
>> T := pidep cext (fun t =>
>>        liftdep (ctyp (object.arrow (object.vartyp t) (object.vartyp t))))
```

<!--
```makam
typeof (lamdep cext (fun t =>
         (liftdep (iterm (object.lam (object.vartyp t) (fun x => x)))))) T ?
>> Yes:
>> T := pidep cext (fun t => liftdep (ctyp (object.arrow (object.vartyp t) (object.vartyp t)))).
```
-->

STUDENT. Look, even the Makam REPL is excited!

ADVISOR. Wait until it sees what we have in store for it next: open STLC terms in our
indices!

STUDENT. Good thing I've printed out the contextual types paper by
\citet{nanevski2008contextual}. (...) OK, so it says here that we can use contextual types
to record, at the type level, the context that open terms depend on. So let's say, an open
`object.term` of type $\tau$ that mentions variables of a $\Phi$ context would have a
contextual type of the form $[\Phi] \tau$. This is some sort of modal typing, with a precise context.

ADVISOR. Right. So in our case, open STLC terms depend on a number of variables, and we will need to keep track of the STLC types of those variables, in order to maintain type safety. So, let's add a new dependent index for open STLC terms, and a dependent classifier for their contextual types, which record the types of the variables that the term depends on, as well as the actual type of the term itself.

STUDENT. Let me see. I think something like this is what we want:

```makam
iopen_term : bindmany object.term object.term -> depindex.
cctx_typ : list object.typ -> object.typ -> depclassifier.
```

ADVISOR. That looks right to me. I can write the classification and well-formedness rules for those.

<!--
```makam
foreach : [A] (A -> prop) -> list A -> prop.
foreach P [].
foreach P (HD :: TL) :- P HD, foreach P TL.
```
-->

```makam
depclassify (iopen_term XS_E) (cctx_typ TS T) :-
  openmany XS_E (pfun xs e =>
    assumemany object.typeof xs TS (object.typeof e T),
    foreach object.wftyp TS).
depwf (cctx_typ TS T) :- foreach object.wftyp TS, object.wftyp T.
```

STUDENT. That makes a lot of sense. I see you are also checking well-formedness for the
types that the context introduces; and `foreach` is exactly like `map`, but there's no
output, so it applies a single-argument predicate to each element of the list.

ADVISOR. Right. We now get to the tricky part: referring to variables that stand for open
terms within other terms! You know what those are, right? Those are Object-level
Object-level Meta-variables.

STUDENT. My head hurts; I'm getting [OOM](https://en.wikipedia.org/wiki/Out_of_memory) errors. Maybe this is easier to implement in Makam than to talk about.

ADVISOR. Maybe so. Well, let me just say this: those variables will stand for open terms that depend on a specific context $\Phi$, but we might use them at a different context $\Phi'$. We need a *substitution* $\sigma$ to go from the context they were defined into the current context.

STUDENT. OK, and then we need to apply that substitution $\sigma$ when we substitute an
actual open term for the metavariable. I know what to do:

\vspace{-0.5em}
```makam
%extend object.
varmeta : depvar -> list term -> term.
typeof (varmeta V ES) T :- depclassify V (cctx_typ TS T), map object.typeof ES TS.
%end.
depsubst_applies Var (object.varmeta Var _).
depsubst_cases Var (iopen_term XS_E) (object.varmeta Var ES) Result :-
  applymany XS_E ES E', depsubst_aux Var (iopen_term XS_E) E' Result.
```

ADVISOR. That should be it; let's try this out! Let's do meta-level application, maybe?
So, take a "function" body that needs a single argument, and an instantiation for that
argument, and do the substitution at the meta-level. This will be sort of like inlining. And let's use unification variables wherever it makes sense, to push our rules to infer what they can for themselves!

```makam-noeval
typeof (lamdep _ (fun t1 => (lamdep _ (fun t2 =>
       (lamdep (cctx_typ [object.vartyp t1] (object.vartyp t2)) (fun f =>
       (lamdep _ (fun a => (liftdep (iopen_term (bindbase (
         (object.varmeta f [object.varterm a]))))))))))))) T ?
>> Yes:
>> T := (pidep cext (fun t1 => pidep cext (fun t2 =>
>>      (pidep (cctx_typ [object.vartyp t1] (object.vartyp t2)) (fun f =>
>>      (pidep (ctyp (object.vartyp t1)) (fun a =>
>>      (liftdep (cctx_typ [] (object.vartyp t2)))))))))).
```

<!--

```makam
typeof (lamdep _ (fun t1 => (lamdep _ (fun t2 =>
       (lamdep (cctx_typ [object.vartyp t1] (object.vartyp t2)) (fun f =>
       (lamdep _ (fun a => (liftdep (iopen_term (body (
         (object.varmeta f [object.varterm a]))))))))))))) T ?
>> Yes:
>> T := (pidep cext (fun t1 => pidep cext (fun t2 => (pidep (cctx_typ [object.vartyp t1] (object.vartyp t2)) (fun f => (pidep (ctyp (object.vartyp t1)) (fun a => (liftdep (cctx_typ [] (object.vartyp t2)))))))))).
```

```makam
(eq _FUNCTION 
       (lamdep _ (fun t1 => (lamdep _ (fun t2 =>
       (lamdep (cctx_typ [object.vartyp t1] (object.vartyp t2)) (fun f =>
       (lamdep _ (fun a => (liftdep (iopen_term (body (
         (object.varmeta f [object.varterm a]))))))))))))),
 typeof (appdep (appdep (appdep _FUNCTION (ityp object.nat)) (ityp object.nat))
           (iopen_term (bind (fun x => body (object.succ x))))) T) ?
>> Yes:
>> T := pidep (ctyp object.nat) (fun a => liftdep (cctx_typ nil object.nat)).
```
-->

\begin{scenecomment}
(Our heroes try out a few more examples to convince themselves that this works.)
\end{scenecomment}

STUDENT. That's it! That's it! I cannot believe how easy this was!

AUDIENCE. Neither can we believe that you thought this was easy!

AUTHOR. Trust me, you should have seen how many weeks it took me to implement something
like this in OCaml.... it was enough to make me start working on Makam. That took two years,
but now we can at least show it in 24 pages of a single-column PDF!

ADVISOR. Where are all these voices coming from?

STUDENT. \textit{(Joke elided to avoid issues with double-blind submission.)}
