# Where our heroes reflect on structural recursion

<!--
```makam
%use "05-patterns.md".
tests: testsuite. %testsuite tests.
```
-->

STUDENT. Type synonyms? You mean, introducing type definitions like `type natpair = nat * nat`? That does not seem particularly tricky.

ADVISOR. I think we will face a couple of interesting issues with it. Let me write out the necessary pen-and-paper rules first, so that we are on the same page. We'll do top-level type definitions, so let's add a top-level notion of programs, and a well-formedness judgement for them. We also need an additional environment to store type definitions:

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

STUDENT. Right, we will need the conversion rule, so that we identify types up to expanding their definitions; that's $\delta$-equality... And I see you haven't listed out all the rules for that, but those are quite standard.

ADVISOR. Still, there are quite a few of those rules. Want to give this a try?

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

Well, I can do the conversion rule and the type equality judgement too.... I will name that `typeq`. I'll just write the one rule for now, which should be sufficient for a small example:

```
typeq : (T1: typ) (T2: typ) -> prop.
typeof E T :- typeof E T', typeq T T'.
typeq A T :- typedef A T.

wfprogram (lettype (arrow onat onat) (fun a =>
          (main (lam a (fun f => (app f ozero)))))) ?
>> (Complete and utter silence)
```

<!--
```makam
typeq : (T1: typ) (T2: typ) -> prop.
```
-->

ADVISOR. Time to `Ctrl-C` out of the infinite loop?

STUDENT. Oh. Oh, right. I guess we hit a case where the proof search strategy of Makam fails to make progress?

ADVISOR. Correct. The loop happens when the new `typeof` rule gets triggered: it has `typeof E T'` as a premise, but the same rule still applies to solve that goal, so the rule will fire again, and so on. Makam just does depth-first search right now; until my friend implements a more sophisticated search strategy, we need to find another way to do this. 

STUDENT. I see. I guess we should switch to an algorithmic type system then.

ADVISOR. Yes. Fortunately we can do that with relatively painless edits and additions. Consider
this: we only need to use the conversion rule in cases where we already know something about the
type `T` of an expression `E`, but the typing rules require that `E` has a type `T'` of some other
form. That was the case above -- for `E = f`, we knew that `T = a`, but the typing rule for `app`
required that `T' = arrow T1 T2` for some `T1`, `T2`.

STUDENT. Oh. Do you mean this in bi-directional typing terms? So, doing type analysis of
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

`eq` is a standard-library predicate that simply attempts unification of the two arguments:

```
eq : A -> A -> prop. eq X X.
```

STUDENT. If we ever made a paper submission out of this, the reviewers would not be happy
about this rule. But sure. We still need to define `typeq` now; maybe I'll do this by
attempting to reduce both arguments to the same normal form.

```
typnf : A -> A -> prop.
typeq T T' :- typnf T Tnf, typnf T' Tnf.
```

Oh, and we should add the
conversion rule for `typeof_patt`, but that's almost identical as for terms. (...) I'll do `typnf` next.

<!--
```makam
typeof_patt (P : patt A B) T S S' :-
  not(refl.isunif T),
  typeof_patt P T' S S',
  typeq T T', not(eq T T').
```
-->

```
typnf A T' :- typedef A T, typnf T T'.
typnf (arrow T1 T2) (arrow T1' T2') :-
  typnf T1 T1', typnf T2 T2'.
typnf (arrowmany TS T) (arrowmany TS' T') :-
  map typnf TS TS', typnf T T'.
...
```

ADVISOR. Writing boilerplate is not fun, is it?

STUDENT. It is not. I wish we could just write the first rule `typnf`; it's the only important
one, after all. All the other ones just propagate the structural recursion through. Also,
whenever we add a new constructor for types, we'll have to remember to add a `typnf` rule
for it....

ADVISOR. Right. Let's just use some magic instead.

<!--
```makam
structural_recursion : [B] forall A (A -> A -> prop) -> B -> B -> prop.
```
-->

```makam
typnf : [A] A -> A -> prop.
typnf A T' :- typedef A T, typnf T T'.
(* typnf T T' :- structural_recursion @typnf T T'. *)
```

<!--
```makam
typeq T T' :- typnf T Tnf, typnf T' Tnf.
```
-->

\begin{scenecomment}
(Hagop is suddenly feeling faint by what will obviously be the main point of the rest of this chapter.)
\end{scenecomment}

STUDENT. ... What just happened. Is `structural_recursion` some special Makam trick I don't know about yet?

ADVISOR. Indeed. There is a little bit of trickery involved here, but you will see that
there is much less of it than you would expect, upon close reflection. `structural_recursion` is
just a normal standard-library predicate like any other; it essentially applies a polymorphic predicate "structurally"
to a term. Its implementation will be a little special of course. But let's just think about how you would
write the rest of the rules of `typnf` generically, to perform structural recursion.

STUDENT. OK. Well, for every top-level `typ` we visit, we essentially need to find any `typ`s contained in it,
and apply `typnf` to them; and we would keep everything else the same.

ADVISOR. Right, or equivalently, we can do this one constructor at a time: for everything that we visit, we
keep the constructor the same, and recurse on its arguments. We'll eventually get to any `typ`s contained, even
if they're inside some other type, like in a `list`. Something like:

```
typnf (Constructor Arguments) (Constructor Arguments') :- map typnf Arguments Arguments'.
```

STUDENT. I see! That's why you made `typnf` polymorphic above; even if we start visiting a `typ` at the top-level,
some of its constituents might be of different type.

ADVISOR. Exactly. Now, the list of `Arguments` -- can you come up with a type for them?

STUDENT. We can use the GADT of heterogeneous lists for them; not all the arguments of each constructor are of the
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

STUDENT. Fair enough. So, going back to our generic rule -- is there a way to actually write it? Maybe there's a reflective predicate we can use, similar to how we used `refl.isunif` before to tell if a term is an uninstantiated unification variable?

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
refl.headargs : (Term: TermT) (Head: HeadT) (Args: hlist ArgsTS) -> prop.

arrowmany : (TS: list typ) (T: typ) -> typ.
refl.headargs Term Head Args :-
  not(refl.isunif Term), eq Term (arrowmany TS T),
  eq Head arrowmany, eq Args (hcons TS (hcons T hnil)).
```

STUDENT. I see. I think I can write the generic rule for `typnf` now then!

```makam
typnf T T' :-
  refl.headargs T Head Args,
  hmap @typnf Args Args',
  refl.headargs T' Head Args'.
```

ADVISOR. Correct. We should now be able to proceed to defining the boilerplate generically. Let's do it as a reusable higher-order predicate for structural recursion. I'll give you the type; you fill in the first case:

```
structural_recursion : [B] (forall A (A -> A -> prop)) -> B -> B -> prop.
```

STUDENT. Let me see. Oh, so, the first argument -- are we doing this in open-recursion style? Maybe that's the predicate for recursive calls. I need to deconstruct a term, apply the recursive call.... How is this?

```makam
structural_recursion Rec X Y :-
  refl.headargs X Constructor Arguments,
  hmap Rec Arguments Arguments',
  refl.headargs Y Constructor Arguments'.
```

AUDIENCE. I'm sure this was not your first attempt in the unabridged version of this story!

ADVISOR. Wait, who said that? Anyway. That looks great! And you're right about using `refl.headargs` in the other direction, to reconstruct a new term with the same constructor and different arguments.

STUDENT. Are we done?

ADVISOR. Almost there! We just need to handle the case of the meta-level function type. It does not make sense to destructure functions using `refl.headargs`; so, that fails for functions, and we have to treat them specially:

```makam
structural_recursion Rec (X : A -> B) (Y : A -> B) :-
  (x:A -> structural_recursion Rec x x -> structural_recursion Rec (X x) (Y x)).
```

```makam
structural_recursion P X Y :- print (X, Y), refl.isunif X, not(refl.isunif Y), eq X Y.
structural_recursion P X Y :- print (X, Y, "right"), refl.isunif Y, not(refl.isunif X), eq X Y.
```

STUDENT. This is exciting; I hope it is part of the standard library of Makam. I can do `teq` in a few lines now!

```
typnf : [A] A -> A -> prop.
typeq T T' :- not(eq T T'), typnf T Tnf, typnf T' Tnf.
typnf A T' :- typedef A T, typnf T T'.
typnf T T' :- structural_recursion @typnf T T'.
```

ADVISOR. That is exactly right! So, we've minimized the boilerplate, and we won't need any
adaptation when we add a new constructor -- even if we make use of all sorts of new and complicated types.

STUDENT. That's right: we did not do anything special for the binding forms we defined.... quite a payoff for a small amount of code! But, wait, isn't `structural_recursion` missing a case: that of uninstantiated unification variables?

ADVISOR. It is, but in my experience, it's better to define how to handle unification variables as needed, in each new structurally recursive predicate. In this case, we're only supposed to use `teq` with ground terms, so it's fine if we fail when we encounter a unification variable.

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
```

```makam
%trace+ typnf.
wfprogram (lettype (product [onat, onat]) (fun bintuple => main
       (lam bintuple
            (fun x => 
    case_or_else x
    (patt_tuple (pcons patt_wild (pcons patt_wild pnil)))
    (vbody (tuple [x, ozero]))
    (tuple [tuple [ozero, ozero], ozero])
  )))) ?
>> Yes.
%trace- typnf.
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
