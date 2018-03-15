# Where our heroes tackle a new level of meta, dependencies, and contexts

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
\newcommand\aq[1]{\ensuremath{\texttt{aq}(#1)}}

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
a way to return (or "lift") an object $o$ as a meta-level value $\lift{o}$.

ADVISOR. Good idea. We are getting into many levels of meta -- there's the meta-language
we're using, Makam; there's the object language we are encoding, which is now becoming a meta-language
in itself, let's call that Heterogeneous Meta ML Light (HMML?); and there's the
"object-object" language that HMML is manipulating. And let's keep that last one simple: the simply typed lambda calculus (STLC).

STUDENT. Great. Other options for the language of objects could be -- a language
of natural numbers, equality predicates, and equality proofs, which would be quite similar to the Dependent ML formulation of
\citet{licata2005formulation}; or it could even be the terms of the full meta-language itself, which would be more
similar to a homogeneous, multi-stage language like MetaML \citep{metaml-main-reference}. But in this case,
our objects will be the types and terms of STLC -- actually, the open terms of STLC.
But as a first example, we can just do something that is more standard, where we only need
the closed terms as objects. How about the standard example of a staged `power` function?
Here's a sketch, where I'm using `~I` for antiquotation:

```
let power (n: onat): < stlc.arrow stlc.onat stlc.onat > =
  match n with
    0 => < stlc.lam (fun x => 1) >
  | S (S n') => letobj I = power n' in
      < stlc.lam (fun x => stlc.app ~I (stlc.mult x x)) >
  | S n' => letobj I = power n' in
      < stlc.lam (fun x => stlc.mult (stlc.app ~I x) x) >
```

ADVISOR. It's a plan. So, let's get to it. Should we write some of the system down on paper first?

STUDENT. Yes, that will be necessary. For this example, we need only the lifting construct and the
`letobj` typing rules; we will work on dependent functions afterwards. Here are their typing
rules, which depend on an appropriately defined typing judgment $\Psi \odash o : c$ for objects. We
use $\dep{i}$ for variables standing for objects, which we will call *indices*. And we will need
a way to antiquote indices inside STLC terms, which means that we will have to *extend* the objects as well as their
typing judgment $\dep{\Psi} \odash o : c$ accordingly. 

\vspace{-1.5em}
\begin{mathpar}
\begin{array}{ll}
\rulename{Ob-Ob-Syntax}                                                   & \rulename{HMML-Syntax} \\
\dep{o} ::= (\text{...closed terms of STLC, plus }\aq{\dep{i}}\text{...}) & e ::= \text{...} \; | \; \lift{\dep{o}} \; | \; \texttt{letobj} \; \dep{i} = \dep{o} \; \texttt{in} \; e \\
\dep{o} ::= \text{(...types of STLC...)}                                  & \tau ::= \text{...} \; | \; \lift{\dep{c}}
\end{array} \\

\inferrule[Typeof-LiftObj]
          {\dep{\Psi} \odash \dep{o} : \dep{c}}
          {\Gamma; \dep{\Psi} \vdash \lift{\dep{o}} : \lift{\dep{c}}}

\inferrule[Typeof-LetObj]
          {\Gamma; \dep{\Psi} \vdash e : \lift{\dep{c}} \\ \Gamma; \dep{\Psi}, \; \dep{i} : \dep{c} \vdash e : \tau \\ i \not\in \text{fv}(\tau)}
          {\Gamma; \dep{\Psi} \vdash \texttt{letobj} \; \dep{i} = e \; \texttt{in} \; e' : \tau}

\inferrule[Classof-Antiquote]
          {\dep{i} : \dep{c} \in \Psi}
          {\Psi \odash \aq{\dep{i}} : \dep{c}}
          
\inferrule[Eval-LiftObj]
          {\hspace{1em}}{\lift{\dep{o}} \Downarrow \lift{\dep{o}}}

\inferrule[Eval-LetObj]
          {e \Downarrow \lift{\dep{o}} \\ e'[\dep{o}/\dep{i}] \Downarrow v}
          {\texttt{letobj} \; \dep{i} = e \; \texttt{in} \; e' \Downarrow v}

\inferrule[SubstObj]{}{
  e[\dep{o}/\dep{i}] = e' \; \text{defined by structural recursion, save for:} \; {\bf{\aq{\dep{i}}[\dep{o}/\dep{i}] = \dep{o}}}
}
\end{mathpar}

The typing rules should be quite simple to transcribe to Makam:

```makam
object, class, index : type.
classof : object -> class -> prop.
classof_index : index -> class -> prop.
subst_obj : (I_E: index -> term) (O: object) (E_O'I: term) -> prop.

liftobj : object -> term. liftclass : class -> typ.
typeof (liftobj O) (liftclass C) :- classof O C.

letobj : term -> (index -> term) -> term.
typeof (letobj E EF') T :-
  typeof E (liftclass C), (i:index -> classof_index i C -> typeof (EF' i) T).

eval (liftobj O) (liftobj O).
eval (letobj E I_E') V :-
  eval E (liftobj O), subst_obj I_E' O E', eval E' V.
```

ADVISOR. Great. I'll add the object language in a separate namespace prefix -- we can use `\texttt{\%extend}' for going
into a namespace -- and I'll just copy-paste our STLC code from earlier on. Let me also add our
new antiquote as a new STLC term constructor!

```
%extend stlc.
term : type. typ : type. typeof : term -> typ -> prop.
...
aq : index -> term.
%end.
```

<!--
We don't have to copy-paste the code, we can import the previous file into a separate namespace. But let's add natural numbers too.

```makam
%import "02-stlc.md" as stlc.
%extend stlc.
onat : typ. ozero : term. osucc : term -> term.
mult : term -> term -> term.
typeof ozero onat.
typeof (osucc N) onat :- typeof N onat.
typeof (mult N1 N2) onat :- typeof N1 onat, typeof N2 onat.
eval ozero ozero.
eval (osucc E) (osucc V) :- eval E V.
aq : index -> term.
%end.
```
-->

STUDENT. Time to add STLC terms as `object`s, and their types as `class`es. We can
then give the corresponding rule for `classof`. And I think that's it for the typing rules!

```makam
obj_term : stlc.term -> object. cls_typ : stlc.typ -> class.
classof (obj_term E) (cls_typ T) :- stlc.typeof E T.
stlc.typeof (stlc.aq I) T :- classof_index I (cls_typ T).
```

\begin{scenecomment}
(Hagop transcribes the example from before. Writing out the term is long, so finds himself
wishing that Makam supported some way to write terms of object languages in their native syntax;
curiously, he also finds himself wishing that he had a stack of blank pages.)
\end{scenecomment}

```
typeof (..long term..) T ?
>> Yes:
>> T := arrow onat (liftclass (cls_typ (stlc.arrow stlc.onat stlc.onat))).
```

<!--
```makam
typeof (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero))))
    )], power)))) T ?
>> Yes:
>> T := arrow onat (liftclass (cls_typ (stlc.arrow stlc.onat stlc.onat))).
```

```makam
typeof (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
    (case_or_else n
      (patt_osucc (patt_osucc patt_var))
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.app (stlc.aq i) (stlc.mult x x))))))))
    (case_or_else n
      (patt_osucc patt_var)
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.mult x (stlc.app (stlc.aq i) x))))))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero))))
    ))
    )], power)))) T ?
>> Yes:
>> T := arrow onat (liftclass (cls_typ (stlc.arrow stlc.onat stlc.onat))).
```
-->

\input{generated/todo}

ADVISOR. I will set up the structural recursion for `subst_obj` now. I have a trick
up my sleeve I haven't told you about yet!

<!--
```makam
%extend clause.
demand_applies : prop -> list clause -> prop.
demand_applies Goal (HD :: TL) <-
  if applies Goal HD
  then success
  else demand_applies Goal TL.
%end.

%extend demand.
applies : prop -> prop.
applies Goal <- aux_demand clause.demand_applies Goal.
%end.

%extend refl.
rules_apply : prop -> prop.
rules_apply P :- demand.applies P.
%end.
```
-->

```makam
subst_obj_aux, subst_obj_cases : [Any]
  (Var: index) (Replace: object) (Where: Any) (Result: Any) -> prop.
subst_obj I_Typ O Typ_O'I :-
  (i:index -> subst_obj_aux i O (I_Typ i) Typ_O'I).

subst_obj_aux Var Replace Where Result :-
  if (refl.rules_apply (subst_obj_cases Var Replace Where Result))
  then (subst_obj_cases Var Replace Where Res)
  else (structural_recursion @(subst_obj_aux Var Replace) Where Res).

subst_obj_cases Var (obj_term Replace) (stlc.aq Var) Replace.
```

STUDENT. Are we done?

<!--
```
%trace+ eval.
eval (app (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
    (case_or_else n
      (patt_osucc (patt_osucc patt_var))
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.app (stlc.aq i) (stlc.mult x x))))))))
    (case_or_else n
      (patt_osucc patt_var)
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.mult x (stlc.app (stlc.aq i) x))))))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero))))
    ))
    )], power)))) (osucc (osucc (osucc ozero)))) V ?
>> Yes:
>> V := ozero.
```
-->

```
wfclass : class -> prop.

lamdep : class -> (index -> term) -> term.
pidep : class -> (index -> typ) -> typ.
typeof (lamdep C EF) (pidep C TF) :-
  (i:index -> classof_index i C -> typeof (EF i) (TF i)), wfclass C.

appdep : term -> object -> term.
typeof (appdep E O) T' :-
  typeof E (pidep C TF), classof O C, subst_obj TF I T'.
```

\begin{mathpar}
\inferrule[Typeof-LamObj]
          {\Gamma; \dep{\Psi}, \; \dep{i} : \dep{c} \vdash e : \tau \\ \dep{\Psi} \odash \dep{c} \; \text{wf}}
          {\Gamma; \dep{\Psi} \vdash \Lambda \dep{i} : \dep{c}.e : \Pi \dep{i} : \dep{c}.\tau}

\inferrule[Typeof-AppObj]
          {\Gamma; \dep{\Psi} \vdash e : \Pi \dep{i} : \dep{c}.\tau \\ \dep{\Psi} \odash \dep{o} : \dep{c}}
          {\Gamma; \dep{\Psi} \vdash e @ \dep{o} : \dep{\text{subst}}(\tau, [\dep{o}/\dep{i}])}
\end{mathpar}

<!-- flipped order in the narrative, we need to declare `wftyp` first.
```
%extend stlc.
wftyp : typ -> prop.
lam : typ -> (term -> term) -> term.
typeof (lam T E) (arrow T T') :-
  (x:term -> typeof x T -> typeof (E x) T'), wftyp T.
%end.
```
-->

STUDENT. Great! I'll make these into dependent indices now, including both types and terms.

```
iterm : stlc.term -> object.     ityp : stlc.typ -> object.
ctyp : stlc.typ -> class.  cext : class.
depclassify (iterm E) (ctyp T) :- stlc.typeof E T.
depclassify (ityp T) cext :- stlc.wftyp T.
depwf (ctyp T) :- stlc.wftyp T.
depwf cext.
```

ADVISOR. Right, we'll need to check that types are well-formed, too. Right now, they are all well-formed by construction, but let's prepare for any additions, by setting up a structurally recursive predicate. The `wftyp_cases` predicate will hold the important type-checking cases, and we will have an extra predicate to say whether those cases apply or not for a specific `typ`.

```
%extend stlc.
wftyp : typ -> prop. wftyp_aux : [A] A -> A -> prop.
wftyp_cases, wftyp_applies : [A] A -> prop.
wftyp T :- wftyp_aux T T.
wftyp_aux T T :- if (wftyp_applies T)
                 then (wftyp_cases T)
                 else (structural_recursion wftyp_aux T T).
%end.
```

<!-- warning: don't redeclare wftyp from above.

```
%extend stlc.
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

```
subst_obj_aux, depsubst_cases : [A] index -> object -> A -> A -> prop.
depsubst_applies : [A] index -> A -> prop.
depsubst F I Res :- (v:index -> subst_obj_aux v I (F v) Res).
subst_obj_aux Var Replace Where Res :-
  if (depsubst_applies Var Where)
  then (depsubst_cases Var Replace Where Res)
  else (structural_recursion (subst_obj_aux Var Replace) Where Res).
```

ADVISOR. Great! We only have one thing missing: we need to close the loop, being able to refer to a dependent variable from within an object-level term or type. 

STUDENT. I got this.

```
%extend stlc.
varterm : index -> term.  vartyp : index -> typ.
typeof (varterm V) T :- depclassify V (ctyp T).
wftyp_applies (vartyp V). wftyp_cases (vartyp V) :- depclassify V cext.
%end.
depsubst_applies Var (stlc.varterm Var).
depsubst_cases Var (iterm Replace) (stlc.varterm Var) Replace.
depsubst_applies Var (stlc.vartyp Var).
depsubst_cases Var (ityp Replace)  (stlc.vartyp Var)  Replace.
```

ADVISOR. This is exciting; let me try it out! I'll do a function that takes an
object-level type and returns the object-level identity function for it.

```-noeval
typeof (lamdep cext (fun t =>
         (liftdep (iterm (stlc.lam (stlc.vartyp t) (fun x => x)))))) T ?
>> Yes!!!!!
>> T := pidep cext (fun t =>
>>        liftdep (ctyp (stlc.arrow (stlc.vartyp t) (stlc.vartyp t))))
```

<!--
```
typeof (lamdep cext (fun t =>
         (liftdep (iterm (stlc.lam (stlc.vartyp t) (fun x => x)))))) T ?
>> Yes:
>> T := pidep cext (fun t => liftdep (ctyp (stlc.arrow (stlc.vartyp t) (stlc.vartyp t)))).
```
-->

STUDENT. Look, even the Makam REPL is excited!

ADVISOR. Wait until it sees what we have in store for it next: open STLC terms in our
indices!

STUDENT. Good thing I've printed out the contextual types paper by
\citet{nanevski2008contextual}. (...) OK, so it says here that we can use contextual types
to record, at the type level, the context that open terms depend on. So let's say, an open
`stlc.term` of type $\tau$ that mentions variables of a $\Phi$ context would have a
contextual type of the form $[\Phi] \tau$. This is some sort of modal typing, with a precise context.

ADVISOR. Right. So in our case, open STLC terms depend on a number of variables, and we will need to keep track of the STLC types of those variables, in order to maintain type safety. So, let's add a new dependent index for open STLC terms, and a dependent classifier for their contextual types, which record the types of the variables that the term depends on, as well as the actual type of the term itself.

STUDENT. Let me see. I think something like this is what we want:

```
iopen_term : bindmany stlc.term stlc.term -> stlc.
cctx_typ : list stlc.typ -> stlc.typ -> class.
```

ADVISOR. That looks right to me. I can write the classification and well-formedness rules for those.

<!--
```
foreach : [A] (A -> prop) -> list A -> prop.
foreach P [].
foreach P (HD :: TL) :- P HD, foreach P TL.
```
-->

```
depclassify (iopen_term XS_E) (cctx_typ TS T) :-
  openmany XS_E (pfun xs e =>
    assumemany stlc.typeof xs TS (stlc.typeof e T),
    foreach stlc.wftyp TS).
depwf (cctx_typ TS T) :- foreach stlc.wftyp TS, stlc.wftyp T.
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
```
%extend stlc.
varmeta : index -> list term -> term.
typeof (varmeta V ES) T :- depclassify V (cctx_typ TS T), map stlc.typeof ES TS.
%end.
depsubst_applies Var (stlc.varmeta Var _).
depsubst_cases Var (iopen_term XS_E) (stlc.varmeta Var ES) Result :-
  applymany XS_E ES E', subst_obj_aux Var (iopen_term XS_E) E' Result.
```

ADVISOR. That should be it; let's try this out! Let's do meta-level application, maybe?
So, take a "function" body that needs a single argument, and an instantiation for that
argument, and do the substitution at the meta-level. This will be sort of like inlining. And let's use unification variables wherever it makes sense, to push our rules to infer what they can for themselves!

```
typeof (lamdep _ (fun t1 => (lamdep _ (fun t2 =>
       (lamdep (cctx_typ [stlc.vartyp t1] (stlc.vartyp t2)) (fun f =>
       (lamdep _ (fun a => (liftdep (iopen_term (bindbase (
         (stlc.varmeta f [stlc.varterm a]))))))))))))) T ?
>> Yes:
>> T := (pidep cext (fun t1 => pidep cext (fun t2 =>
>>      (pidep (cctx_typ [stlc.vartyp t1] (stlc.vartyp t2)) (fun f =>
>>      (pidep (ctyp (stlc.vartyp t1)) (fun a =>
>>      (liftdep (cctx_typ [] (stlc.vartyp t2)))))))))).
```

<!--

```
typeof (lamdep _ (fun t1 => (lamdep _ (fun t2 =>
       (lamdep (cctx_typ [stlc.vartyp t1] (stlc.vartyp t2)) (fun f =>
       (lamdep _ (fun a => (liftdep (iopen_term (body (
         (stlc.varmeta f [stlc.varterm a]))))))))))))) T ?
>> Yes:
>> T := (pidep cext (fun t1 => pidep cext (fun t2 => (pidep (cctx_typ [stlc.vartyp t1] (stlc.vartyp t2)) (fun f => (pidep (ctyp (stlc.vartyp t1)) (fun a => (liftdep (cctx_typ [] (stlc.vartyp t2)))))))))).
```

```
(eq _FUNCTION 
       (lamdep _ (fun t1 => (lamdep _ (fun t2 =>
       (lamdep (cctx_typ [stlc.vartyp t1] (stlc.vartyp t2)) (fun f =>
       (lamdep _ (fun a => (liftdep (iopen_term (body (
         (stlc.varmeta f [stlc.varterm a]))))))))))))),
 typeof (appdep (appdep (appdep _FUNCTION (ityp stlc.nat)) (ityp stlc.nat))
           (iopen_term (bind (fun x => body (stlc.succ x))))) T) ?
>> Yes:
>> T := pidep (ctyp stlc.nat) (fun a => liftdep (cctx_typ nil stlc.nat)).
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
