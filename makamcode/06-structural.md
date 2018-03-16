# Where our heroes reflect on structural recursion

<!--
```makam
%use "05-patterns.md".
tests: testsuite. %testsuite tests.
```
-->

ADVISOR. Your pattern matching encoding looks good! You seem to be getting the hang of this. How
about we do something challenging then? Say, type synonyms?

STUDENT. Type synonyms? You mean, introducing type definitions like `type natpair = nat * nat`? That
does not seem particularly tricky.

ADVISOR. I think we will face a couple of interesting issues with it, the main one being how to do
*structural recursion* in a nice way. But first, let me write out the necessary pen-and-paper rules, so that we are on the same page. We'll do top-level type definitions, so let's add a top-level notion of programs and a well-formedness judgment for them. (We could do modules instead of just programs, but I feel that would derail us a little.) We also need an additional environment to store type definitions:

\vspace{-1.2em}
\begin{mathpar}
\inferrule[Program-Syntax]{}{c ::= \text{main} \; e \; | \; \texttt{type} \; \alpha = \tau \; ; \; c}

\inferrule[WfProgram-Main]{\emptyset; \; \Delta \vdash e : \tau}
          {\Delta \vdash (\text{main} \; e) \; \text{wf}}

\inferrule[WfProgram-Type]{\Delta, \; \alpha = \tau \vdash c \; \text{wf}}
          {\Delta \vdash (\texttt{type} \; \alpha = \tau \; ; \; c) \; \text{wf}}

\inferrule[Typeof-Conversion]
          {\Gamma; \Delta \vdash e : \tau \\ \Delta \vdash \tau =_\delta \tau'}
          {\Gamma; \Delta \vdash e : \tau'}

\inferrule[TypEq-Def]
          {\alpha = \tau \in \Delta}
          {\Delta \vdash \alpha =_\delta \tau}
\cdots
\end{mathpar}

STUDENT. Right, we will need the conversion rule, so that we identify types up to expanding their definitions; that's $\delta$-equality... And I see you haven't listed out all the rules for that, but those are mostly standard.

ADVISOR. Still, there are quite a few of those rules. Want to give transcribing this to Makam a try?

STUDENT. Yes, I got this. I'll add a new `typedef` predicate; I will only use it for local assumptions, to correspond to $\Delta$ context of type definitions. I will also do the well-formed program rules:

```makam
typedef : (NewType: typ) (Definition: typ) -> prop.

program : type. 
main : term -> program. 
lettype : (Definition: typ) (A_Program: typ -> program) -> program.

wfprogram : program -> prop.
wfprogram (main E) :- typeof E T.
wfprogram (lettype T A_Program) :-
  (a:typ -> typedef a T -> wfprogram (A_Program a)).
```

Well, I can do the conversion rule and the type-equality judgment too.... I will name that `typeq`. I'll just write the one rule for now, which should be sufficient for a small example:

```
typeq : (T1: typ) (T2: typ) -> prop.
typeof E T :- typeof E T', typeq T T'.
typeq A T :- typedef A T.

wfprogram (lettype (arrow onat onat) (fun a =>
          (main (lam a (fun f => (app f ozero)))))) ?
>> (Complete silence)
```

<!--
```makam
typeq : [Any] (T1: Any) (T2: Any) -> prop.
```
-->

ADVISOR. Time to `Ctrl-C` out of the infinite loop?

STUDENT. Oh. Oh, right. I guess we hit a case where the proof-search strategy of Makam fails to make progress?

ADVISOR. Correct. The loop happens when the new `typeof` rule gets triggered: it has `typeof E T'` as a premise, but the same rule still applies to solve that goal, so the rule will fire again, and so on. Makam just does depth-first search right now; until my friend implements a more sophisticated search strategy, we need to find another way to do this. 

STUDENT. I see. I guess we should switch to an algorithmic type system then.

ADVISOR. Yes. Fortunately we can do that with relatively painless edits and additions. Consider
this: we only need to use the conversion rule in cases where we already know something about the
type `T` of an expression `E`, but the typing rules require that `E` has a type `T'` of some other
form. That was the case above -- for `E = f`, we knew that `T = a`, but the typing rule for `app`
required that `T' = arrow T1 T2` for some `T1`, `T2`.

STUDENT. Oh. Do you mean this in bidirectional typing terms? So, doing type analysis of
an expression with a concrete type `T` might fail, but synthesizing the type anew could work?

ADVISOR. Exactly, and in that case we have to check that the two types are equal, using `typeq`.
So we need to change the rule you wrote to apply only in the case where `T` starts with a
concrete constructor, rather than when it is an uninstantiated unification variable.

STUDENT. Is that even possible? Is there a way in λProlog to tell whether something is a unification variable?

ADVISOR. There is! Most Prolog dialects have a predicate that does that -- it's usually
called `var`. In Makam it is called `refl.isunif`, the `refl` namespace prefix standing for
*reflective* predicates. So, here's a second attempt:

```
typeof E T :- not(refl.isunif T), typeof E T', typeq T T'.
```

STUDENT. Interesting. But wouldn't this lead to an infinite loop, too? After all, `typeq` is going to be reflexive when we add all rules -- so we could end up in the same situation as before.

ADVISOR. Correct: for every proof of `typeof E T'` through the other rules, a new proof using this
rule will be discovered, which will lead to another proof for it, etc. One fix is to make sure that
this rule is only used once at the end, if typing using the other rules fails. But for now, let's do
a trick to side-step this issue -- let's check that `T` and `T'` are not identical:

```makam
typeof E T :- not(refl.isunif T), typeof E T', typeq T T', not(eq T T').
```

By the way, `eq` is a standard-library predicate that simply attempts unification of the two arguments:

```
eq : A -> A -> prop. eq X X.
```

STUDENT. If we ever made a paper submission out of this, some reviewers would not be happy
about this `typeof` rule. But sure. Oh, and we should add the
conversion rule for `typeof_patt`, but that's almost the same as for terms. (...) I'll do `typeq` next.

<!--
```makam
typeof_patt (P : patt A B) T S S' :-
  not(refl.isunif T),
  typeof_patt P T' S S',
  typeq T T', not(eq T T').
```
-->

```
typeq A T' :- typedef A T, typeq T T'.
typeq T' A :- typedef A T, typeq T T'.
...
```

ADVISOR. I like how you added the symmetric rule, but... this is subtle, but if `A` is a unification variable, we don't want to unify it with an arbitrary synonym. So we need to check that `A` is concrete somehow\footnote{Though not supported in Makam, an alternative to this in other languages based on higher-order logic programming would be to add a \texttt{mode (i o)} declaration for \texttt{typedef}, so that \texttt{typedef A T} would fail if \texttt{A} is not concrete.}:

```
typeq A T' :- not(refl.isunif A), typedef A T, typeq T T'.
typeq T' A :- not(refl.isunif A), typedef A T, typeq T T'.
...
```

STUDENT. I see what you mean. OK, I'll continue on to the rest of the cases....

```
typeq (arrow T1 T2) (arrow T1' T2') :-
  typeq T1 T1', typeq T2 T2'.
typeq (arrowmany TS T) (arrowmany TS' T') :-
  map typeq TS TS', typeq T T'.
...
```

ADVISOR. Writing boilerplate is not fun, is it?

STUDENT. It is not. I wish we could just write the first two rules that you wrote; they're the important
ones, after all. All the others just propagate the structural recursion through. Also,
whenever we add a new constructor for types, we'll have to remember to add a `typeq` rule
for it....

ADVISOR. Right. Let's just use some magic instead.

\begin{scenecomment}
(Roza changes the type definition of \texttt{typeq} to \texttt{typeq : [Any] (T1: Any) (T2: Any) -> prop},
and adds a few lines:)
\end{scenecomment}

<!--
```makam
structural_recursion : [B] forall A (A -> A -> prop) -> B -> B -> prop.
```
-->

```makam
typeq A T' :- not(refl.isunif A), typedef A T, typeq T T'.
typeq T' A :- not(refl.isunif A), typedef A T, typeq T T'.
typeq T T' :- structural_recursion @typeq T T'.
```

STUDENT. ... What just happened. Is `structural_recursion` some special Makam trick I don't know about yet?

ADVISOR. Indeed. There is a little bit of trickery involved here, but you will see that
there is much less of it than you would expect, upon close reflection. `structural_recursion` is
just a normal standard-library predicate like any other; it essentially applies a polymorphic predicate "structurally"
to a term. Its implementation will be a little special of course. But let's just think about how you would
write the rest of the rules of `typeq` generically, to perform structural recursion.

STUDENT. OK. Well, when looking at two `typ`s together, we have to make sure that their constructors are the same and also that any `typ`s they contain as arguments are recursively `typeq`ual. So something like this:

```
typeq (Constructor Arguments) (Constructor Arguments') :-
  map typeq Arguments Arguments'.
```

ADVISOR. Right. Note, though, that the types of arguments might be different than `typ`. So even if we start comparing two types at the top level, we might end up having to compare two lists of types that they contain -- imagine the case for `arrowmany` for example.

STUDENT. I see! That's why you edited `typeq` to be polymorphic above; you have extended it to work on *any type* (of the metalanguage) that might contain a `typ`.

ADVISOR. Exactly. Now, the list of `Arguments` -- can you come up with a type for them?

STUDENT. We can use the GADT of heterogeneous lists for them; not all the arguments of each constructor need to be of the
same type!

```makam
typenil : type. typecons : (T: type) (TS: type) -> type.
hlist : (TypeList: type) -> type.
hnil : hlist typenil. hcons : T -> hlist TS -> hlist (typecons T TS).
```

ADVISOR. Great! We will need a heterogeneous `map` for these lists too. We'll need a polymorphic predicate as
an argument, since we'll have to use it for `Arguments` of different types:

```makam
hmap : [TS] (P: forall A (A -> A -> prop)) (XS: hlist TS) (YS: hlist TS) -> prop.
hmap P hnil hnil.
hmap P (hcons X XS) (hcons Y YS) :- apply P X Y, hmap P XS YS.
```

As I mentioned before, the rank-2 polymorphism support in Makam is quite limited, so you have to use `apply` explicitly to instantiate the polymorphic `P` predicate accordingly and apply it.

STUDENT. Let me try out an example of that:
```makam
hmap @eq (hcons 1 (hcons "foo" hnil)) YS ?
>> Yes:
>> YS := hcons 1 (hcons "foo" hnil).
```

Looks good enough. So, going back to our generic rule -- is there a way to actually write it? Maybe there's a reflective predicate we can use, similar to how we used `refl.isunif` before to tell if a term is an uninstantiated unification variable?

<!--
Switch to a refl.headargs that returns a heterogeneous list.

```makam
%extend refl.

dyn_to_hlist : [T] list dyn -> hlist T -> prop.
dyn_to_hlist [] hnil.
dyn_to_hlist (dyn HD :: TL) (hcons HD TL') :- dyn_to_hlist TL TL'.

headargs : (Term: A) (Head: B) (Arguments: hlist T) -> prop.
headargs Term Head Arguments when refl.isunif Head :-
  .refl.headargs Term Head DynList,
  dyn_to_hlist DynList HList,
  eq Arguments HList.
headargs Term Head Arguments when not(refl.isunif Head) :-
  dyn_to_hlist DynList Arguments,
  .refl.headargs Term Head DynList.
%end.
```
-->

ADVISOR. Exactly -- there is `refl.headargs`. It relates a concrete term to its decomposition into a constructor and a list of arguments\footnote{Other versions of Prolog have predicates toward the same effect; for example, SWI-Prolog \citep{wielemaker2012swi} provides `\texttt{compound\_{}name\_{}arguments}', which is quite similar.}. This is not an extra-logical feature, though: we could define `refl.headargs` without any special support, save for `refl.isunif`, if we maintained a discipline whenever we add a new constructor, roughly like this:

```
refl.headargs : (Term: TermT) (Constr: ConstrT) (Args: hlist ArgsTS) -> prop.

arrowmany : (TS: list typ) (T: typ) -> typ.
refl.headargs Term Constructor Args :-
  not(refl.isunif Term), eq Term (arrowmany TS T),
  eq Constructor arrowmany, eq Args (hcons TS (hcons T hnil)).
```

STUDENT. I see. I think I can write the generic rule for `typeq` now then!

```
typeq T T' :-
  refl.headargs T Constr Args,
  refl.headargs T' Constr Args',
  hmap @typeq Args Args'.
```

ADVISOR. That looks great! Simple, isn't it? You'll see that there are a few more generic cases that are needed, though. Should we do that? We can roll our own reusable `structural_recursion` implementation -- that way we will dispel all magic from its use that I showed you earlier! I'll give you the type; you fill in the first case:

```
structural_recursion : [Any] 
  (RecursivePred: forall A (A -> A -> prop))
  (X: Any) (Y: Any) -> prop.
```

STUDENT. Let me see. Oh, so, the first argument is a predicate -- are we doing this in open-recursion style? I see. Well, I can adapt the case I just wrote above.

```makam
structural_recursion Rec X Y :-
  refl.headargs X Constructor Arguments,
  refl.headargs Y Constructor Arguments',
  hmap Rec Arguments Arguments'.
```

ADVISOR. Nice. Now, this assumes that `X` and `Y` are both concrete terms. What happens when `X` is concrete and `Y` isn't, or the other way around? Hint: you can use `refl.headargs` in the other direction, to reconstruct a term from a constructor and a list of arguments.

STUDENT. Let me think about that a bit. How is this?

```makam
structural_recursion Rec X Y :-
  refl.headargs X Constructor Arguments,
  hmap Rec Arguments Arguments',
  refl.headargs Y Constructor Arguments'.
```

ADVISOR. That is exactly right. You need the symmetric case too, where `Y` is concrete and `X` isn't, but that's entirely similar. Also, there is another type of concrete terms in Makam: meta-level functions! It does not make sense to destructure functions using `refl.headargs`; so, that predicate `refl.headargs` fails for functions, and we have to treat them specially:

```makam
structural_recursion Rec (X : A -> B) (Y : A -> B) :-
  (x:A -> structural_recursion Rec x x -> structural_recursion Rec (X x) (Y x)).
```

STUDENT. Ah, I see! Here you *are* actually relying on the `typecase` aspect of ad-hoc polymorphism, right? To check if `X` and `Y` are of the meta-level function type.

ADVISOR. Exactly. And you know what, that's all there is to it! So, we've minimized the boilerplate, and we won't need any
adaptation when we add a new constructor -- even if we make use of all sorts of new and complicated types.

STUDENT. That's right: we do not need to do anything special for the binding forms we defined, like `bindmany`.... quite a payoff for a small amount of code! But, wait, isn't `structural_recursion` missing a case: what happens if both `X` and `Y` are uninstantiated unification variables?

ADVISOR. You are correct, it would fail in that case. But in my experience, it's better to define how to handle unification variables as needed, in each new structurally recursive predicate. In this case, we should never get into that situation based on how we have defined `typeq`.

\begin{scenecomment}
(Our heroes try out a few examples and convince themselves that this works OK and no endless loops happen when things don't typecheck correctly.)
\end{scenecomment}

<!--
Let us try out an example:

```makam
typeof (lam (product [onat, onat])
            (fun x => 
    case_or_else x
    (patt_tuple (pcons patt_wild (pcons patt_wild pnil)))
    (vbody (tuple [x, ozero]))
    (tuple [tuple [ozero, ozero], ozero])
  )) T ?
>> Yes:
>> T := arrow (product (cons onat (cons onat nil))) (product (cons (product (cons onat (cons onat nil))) (cons onat nil))).
```

```makam
(a:typ -> typedef a (product [onat, onat]) -> typeq a (product [onat, onat])) ?
>> Yes.

(a:typ -> typedef a (product [onat, onat]) -> typeq (product [onat, onat]) a) ?
>> Yes.
```

```makam
wfprogram (lettype (product [onat, onat]) (fun bintuple => main
       (lam bintuple
            (fun x => 
    case_or_else x
    (patt_tuple (pcons patt_wild (pcons patt_wild pnil)))
    (vbody (tuple [x, ozero]))
    (tuple [tuple [ozero, ozero], ozero])
  )))) ?
>> Yes.
```

Let us make sure we do not diverge on type error:

```makam
wfprogram (lettype (product [onat, onat]) (fun bintuple => main
       (lam bintuple
            (fun x => 
    case_or_else x
    (patt_tuple (pcons patt_wild pnil))
    (vbody (tuple [x, ozero]))
    (tuple [tuple [ozero, ozero], ozero])
  )))) ?
>> Impossible.
```
-->
