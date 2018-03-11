# Where our heroes reflect on structural recursion

<!--
```makam
%use "05-miniml.md".
tests: testsuite. %testsuite tests.
```
-->

STUDENT. Type synonyms? Difficult? Why? Doesn't this work?

```makam
type_synonym : dbind typ T typ -> (typeconstructor T -> program) -> program.
type_synonym_info : typeconstructor T -> dbind typ T typ -> prop.
wfprogram (type_synonym Syn Program') :-
  (t:(typeconstructor T) -> type_synonym_info t Syn -> wfprogram (Program' t)).
```

ADVISOR. Sure, that works. How about the typing rule for them, then? We'll need
something like the conversion rule:

\begin{center}$\inferrule{\Gamma \vdash e : \tau \\ \tau =_{\delta} \tau'}{\Gamma \vdash e : \tau'}$\end{center}

STUDENT. Right, $=_{\delta}$ is equality up to expanding the type synonyms.

ADVISOR. Yes, we'll definitely need a type-equality predicate.

```makam
teq : typ -> typ -> prop.
```

STUDENT. OK. And then we do this?

```
typeof E T :- typeof E T', teq T T'.
```

ADVISOR. That would be nice, but we'll go into an infinite loop if that rule gets
used.

STUDENT. Oh. Oh, right. There is a specific proof-finding strategy in logic programming, and it can't always work.... I guess we have to switch our rules to an algorithmic type-system
instead.

ADVISOR. Precisely. Well, luckily, we can do that to a certain extent, without rewriting everything. Consider this: we only need to use the conversion rule in cases where we
already know something about the type `T` of the expression, but our typing rules do not
match that type.

STUDENT. Oh. Do you mean that in bi-directional typing terms? So, doing type analysis of
an expression with a concrete type `T` might fail, but synthesizing the type anew could work?

ADVISOR. Exactly, and in that case we have to check that the two types are equal, using `teq`.
So we need to change the rule you wrote to apply only in the case where `T` starts with a
concrete constructor, rather than when it is an uninstantiated unification variable.

STUDENT. Is that even possible? Is there a way in λProlog to tell whether something is a unification variable?

ADVISOR. There is! Most Prolog dialects have a predicate that does that -- it's usually
called `var`. In Makam it is called `refl.isunif`, the `refl` namespace prefix standing for
*reflective* predicates. So, here's a second attempt:

```
typeof E T :- not(refl.isunif T), typeof E T', teq T T'.
```

STUDENT. Interesting. But wouldn't this lead to an infinite loop, too? After all, `teq` is reflexive -- so we could end up in the same situation as before.

ADVISOR. Correct: for every proof of `typeof E T'` through the other rules, a new proof
using this rule will be discovered, which will lead to another proof for it, etc. One fix
is to make sure that this rule is only used once at the end, if typing using the normal
rules fails.

STUDENT. So, something like this:

```
typeof, typeof_cases, typeof_conversion : term -> typ -> prop.
typeof E T :- if (typeof_cases E T) then success else (typeof_conversion E T).
typeof_cases (app E1 E2) T' :- typeof E1 (arrow T1 T2), typeof E2 T1.
...
typeof_conversion E T :- not(refl.isunif T), typeof_cases E T', teq T T'.
```

ADVISOR. Yes, but let's do a trick to side-step the issue for now. We will force the rule
to only fire once for each expression `E`, by remembering that we have used the rule
already:

```makam
already_in : [A] A -> prop.
typeof E T :- not(refl.isunif T), not(already_in (typeof E)),
              (already_in (typeof E) -> typeof E T'), teq T T'.
```

STUDENT. If we ever made a paper submission out of this, the reviewers would not be happy
about this rule. But sure. We still need to define `teq` now. Oh, and we should add the
conversion rule for patterns, but that's almost identical as for terms. (...) I'll do `teq`....

<!--
```makam
typeof (P : patt A B) S' S T :-
  not(refl.isunif T),
  not(already_in (typeof P)),
  (already_in (typeof P) -> typeof P S' S T'),
  teq T T'.
```
-->

```
teq (tconstr TC Args) T' :- type_synonym_info TC Syn, applymany Syn Args T, teq T T'.
teq T' (tconstr TC Args) :- type_synonym_info TC Syn, applymany Syn Args T, teq T' T.
teq (arrow T1 T2) (arrow T1' T2') :- teq T1 T1', teq T2 T2'.
teq (arrowmany TS T) (arrowmany TS' T') :- map teq TS TS', teq T T'.
...
```

ADVISOR. Writing boilerplate is not fun, is it?

STUDENT. It is not. I wish we could just write the first two rules; they are the important
ones, after all. All the other ones just propagate the structural recursion through. Also,
whenever we add a new constructor for types, we'll have to remember to add a `teq` rule
for it....

ADVISOR. Why don't we reflect a bit on this? Ideally we would only write a generic rule,
to handle any concrete constructor applied to a number of arguments. Something like:

```
teq (Constructor Arguments) (Constructor Arguments') :- map teq Arguments Arguments'.
```

STUDENT. Right, so in the example of the `arrow` type, `Constructor` would match `arrow` and arguments would be instantiated with `[T1, T2]`. But we are not really guaranteed that all arguments are of `typ` type, or even that they are all of the same type, right? Take `arrowmany` for example! The argument list needs to be heterogeneous.

ADVISOR. Glad you figured that out. We can do that using the existential type -- let's call it `dyn` --, so the arguments can be of `list dyn` type. And we'll need to make `teq` polymorphic, handling any type that includes a `typ`:

```
dyn : type.  dyn : A -> dyn.
teq : [A] A -> A -> prop.
```

STUDENT. We'll also need a `map` for these heterogeneous lists, too. I believe it will need a polymorphic function as an argument, so that it can be used at different types for different elements of the list. So something like this:

```
map : (forall A. [A] A -> A -> prop) -> list dyn -> list dyn -> prop.
```

ADVISOR. Right, we'd need higher-rank types here. There's a problem with the alternative:
```
map : [A] (A -> A -> prop) -> list dyn -> list dyn -> prop
```
\noindent
In the first `cons` cell, this would instantiate the type `A` to the type of the first
element of the list, making further applications to different types impossible.

STUDENT. Exactly. Does Makam support higher-rank polymorphism?

ADVISOR. Unfortunately it does not right now, but it should. Nor do any other λProlog implementations that I know of, though. Also, there is no way to refer to a polymorphic constant without implicitly instantiating it with new type variables. So we have to use a helper predicate right now, called `dyn.call`, to avoid that issue:

```
dyn.call : [B] (A -> A -> prop) -> B -> B -> prop.
dyn.map : (A -> A -> prop) -> list dyn -> list dyn -> prop.
dyn.map P [] [].
dyn.map P (HD :: TL) (HD' :: TL') :- dyn.call P HD HD', dyn.map P TL TL'.
```

STUDENT. Fair enough. So, going back to our generic rule -- is there a way to actually write it? Maybe there's another reflective predicate we can use?

ADVISOR. Exactly -- there is `refl.headargs`. If a term is concrete, it decomposes it into a constructor and a list of arguments\footnote{Other versions of Prolog have predicates toward the same effect; for example, SWI-Prolog \citep{wielemaker2012swi} provides `\texttt{compound\_{}name\_{}arguments}', which is quite similar.}. This isn't a hack, though: we could define `refl.headargs` without any special support, save for `refl.isunif`, if we maintained a discipline whenever we add a new constructor:
```
arrowmany : list typ -> typ -> typ.
refl.headargs Term Head Args :- not(refl.isunif Term), eq Term (arrowmany TS T),
                                eq Head arrowmany, eq Args [dyn TS, dyn T].
```

STUDENT. So `refl.headargs` has this type:
```
refl.headargs : B -> A -> list dyn -> prop.
```

ADVISOR. Correct. We should now be able to proceed to defining the boilerplate generically. Let's do it as a reusable higher-order predicate for structural recursion. I'll give you the type; you fill in the first case:

```makam
structural_recursion : [A B] (A -> A -> prop) -> B -> B -> prop.
```

STUDENT. Let me see. Oh, so, the first argument -- are we doing this in open-recursion style? Maybe that's the predicate for recursive calls. I need to deconstruct a term, apply the recursive call.... How is this?

```makam
structural_recursion Rec X Y :-
  refl.headargs X Constructor Arguments,
  dyn.map Rec Arguments Arguments',
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

STUDENT. This is exciting; I hope it is part of the standard library of Makam. I can do `teq` in a few lines now!

```makam
teq' : [A] A -> A -> prop.
teq T T' :- teq' T T'.
teq' (tconstr TC Args) T' :-
  type_synonym_info TC Synonym, applymany Synonym Args T, teq' T T'.
teq' T' (tconstr TC Args) :-
  type_synonym_info TC Synonym, applymany Synonym Args T, teq' T' T.
teq' T T' :- structural_recursion teq' T T'.
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
wfprogram (
  (type_synonym (dbindnext (fun a => dbindbase (product [a, a])))
  (fun bintuple => 
  
  main (lam (tconstr bintuple [product [nat, nat]])
            (fun x => 
    case_or_else x
    (patt_tuple [patt_tuple [patt_wild, patt_wild], patt_tuple [patt_wild, patt_wild]])
    (dbindbase (tuple []))
    (tuple [])
  ))
))) ?
>> Yes.
```

Let us make sure we do not diverge on type error:

```makam
wfprogram (
  (type_synonym (dbindnext (fun a => dbindbase (product [a, a])))
  (fun bintuple => 
  
  main (lam (tconstr bintuple [product [nat, nat]])
            (fun x => 
    case_or_else x
    (patt_tuple [patt_tuple [patt_wild], patt_tuple [patt_wild, patt_wild]])
    (dbindbase (tuple []))
    (tuple [])
  ))
))) ?
>> Impossible.
```
-->
