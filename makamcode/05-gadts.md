# In which the legend of the GADTs and the Ad-Hoc Polymorphism is recounted

<!--
```makam
%use "04-bindmany.md".
tests: testsuite. %testsuite tests.
```
-->

\identNormal\it

Once upon a time, our republic lacked one of the natural wonders that it is now well-known for, and
which is now regularly enjoyed by tourists and inhabitants alike. I am talking of course about the
Great Arboretum of Dangling Trees, known as GADTs for short. Then settlers from the far-away land of
the Dependency started coming to the republic and started speaking of Lists that Knew Their Lengths,
of Terms that Knew Their Types, of Collections of Elements that were Heterogeneous, and about the
other magical beings of their home.  And they set out to build a natural environment for these
beings on the republic, namely the GADTs that we know and love, to remind them of home a little. And
their work was good and was admired by many.

A long time passed, and dispatches from another far-away land came to the republic, written by authors
whose names are now lost in the sea of anonymity, and I fear might forever remain so. And the
dispatches went something like this.

\rm

AUTHOR. ... In my land of \lamprolog that I speak of, the type system is a subset of System
F$_\omega$ that should be familiar to you -- the simply typed lambda calculus, plus prenex
polymorphism, plus simple type constructors of the form `type * ... * type -> type`. There is also a
limited form of rank-2 polymorphism, allowing types of the form `forall A T`, which are inhabited by
unapplied polymorphic constants through the notation `@foo`. There is a `prop` sort for
propositions, which is a normal type, but also a bit special: its terms are not just values but are
also computations, activated when queried upon.

However, the language of this land has a distinguishing feature, called Ad-Hoc Polymorphism. You
see, the different rules that define a predicate in our language can *specialize* their type
arguments. This can be used to define polymorphic predicates that behave differently for different
types, like this, where we are essentially doing a `typecase` and we choose a rule depending on the
*type* of the argument (as opposed to its value):

```nohighlight
print : [A] A -> prop.
print (I: int) :- (... code for printing integers ...)
print (S: string) :- (... code for printing strings ...)
```

The local dialects Teyjus \citep{teyjus-main-reference,teyjus-2-implementation} and Makam include
this feature, while it is not encountered in other dialects like ELPI
\citep{elpi-main-reference}. In the Makam dialect in particular, type variables are understood to be
parametric by default. In order to make them ad-hoc and allow specializing them in rules, we need to
denote them using the `[A]` notation.

Of course, this feature has both to do with the statics as well as the dynamics of our language: and
while dynamically it means something akin to a `typecase`, statically, it means that rules might
specialize their type variables, and this remains so for type-checking the whole rule.

But... aha! Is it not type specialization during pattern matching that is an essential feature of the
GADTs of your land?  Maybe that means that we can use Ad-Hoc Polymorphism not just to do `typecase`
but also to work with GADTs in our land? Consider this! The venerable List that Knows Its Length:

```makam-stdlib
zero : type. succ : type -> type.
vector : type -> type -> type.
vnil : vector A zero.
vcons : A -> vector A N -> vector A (succ N).
```

And now for the essential `vmap`:

```makam-stdlib
vmap : [N] (A -> B -> prop) -> vector A N -> vector B N -> prop.
vmap P vnil vnil.
vmap P (vcons X XS) (vcons Y YS) :- P X Y, vmap P XS YS.
```

In each rule, the first argument already specializes the `N` type -- in the first rule to `zero`,
in the second, to `succ N`. And so erroneous rules that do not respect this specialization
would not be accepted as well-typed sayings in our language:

```
vmap P vnil (vcons X XS) :- ...
```

And we should note that in this usage of Ad-Hoc Polymorphism for GADTs, it is only the increased
precision of the statics that we care about. Dynamically, the rules for `vmap` can perform
normal term-level unification and only look at the constructors `vnil` and `vcons` to see
whether each rule applies, rather than relying on the `typecase` aspects we spoke of before.

Coupling this with the binding constructs that I talked to you earlier about, we can build
new magical beings, like the *Bind that Knows Its Length*:

\importantCodeblock{}
```makam-stdlib
vbindmany : (Var: type) (N: type) (Body: type) -> type.
vbody : Body -> vbindmany Var zero Body.
vbind : (Var -> vbindmany Var N Body) -> vbindmany Var (succ N) Body.
```
\importantCodeblockEnd{}

(Whereby I am using notation of the Makam dialect in my definition of `vbindmany` that allows me to name
parameters, purely for the purposes of increased clarity.)

In the `openmany` version for `vbindmany`, the rules are exactly as before, though the static
type is more precise:

```makam-stdlib
vopenmany : [N] vbindmany Var N Body -> (vector Var N -> Body -> prop) -> prop.
vopenmany (vbody Body) Q :- Q vnil Body.
vopenmany (vbind F) Q :-
  (x:A -> vopenmany (F x) (fun xs => Q (vcons x xs))).
```

We can also showcase the *Accurate Encoding of the Letrec*:

\importantCodeblock{}
```makam
vletrec : vbindmany term N (vector term N * term) -> term.
```
\importantCodeblockEnd{}

And that is the way that it turns out that our land of \lamprolog supports GADTs, without needing the addition of any feature. It is all thanks to the existing support for Ad-Hoc Polymorphism, which has been a staple since the days of yore \citep{lambdaprolog-early-reference}. Who knew!

\identDialog

<!--
```makam-stdlib
vapplymany : [N] vbindmany Var N Body -> vector Var N -> Body -> prop.
vapplymany (vbody Body) vnil Body.
vapplymany (vbind F) (vcons X XS) Body :- vapplymany (F X) XS Body.

vassumemany : [N] (A -> B -> prop) -> vector A N -> vector B N -> prop -> prop.
vassumemany P vnil vnil Q :- Q.
vassumemany P (vcons X XS) (vcons Y YS) Q :- (P X Y -> vassumemany P XS YS Q).
```

```makam
typeof (vletrec XS_DefsBody) T' :-
  vopenmany XS_DefsBody (pfun XS (Defs, Body) =>
    vassumemany typeof XS TS (vmap typeof Defs TS),
    vassumemany typeof XS TS (typeof Body T')).

typeof (vletrec (vbind (fun f => vbody (vcons (lam T (fun x => app f (app f x))) vnil, f)))) T' ?
>> Yes:
>> T' := arrow T T,
>> T := T.
```
-->
