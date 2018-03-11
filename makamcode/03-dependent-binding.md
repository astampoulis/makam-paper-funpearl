# Where the legend of the GADTs and the Ad-Hoc Polymorphism is recounted

<!--
```makam
%use "02-binding-forms.md".
test03: testsuite. %testsuite test03.
```
-->

\identNormal\it

Once upon a time, our republic lacked one of the natural wonders that it is now well-known for, and
which is now regularly enjoyed by tourists and inhabitants alike. I am talking of course about the
Great Arboretum of Dangling Trees, known as GADTs for short. Then settlers from the far-away land of
the Dependency started coming to the republic, and started speaking of Lists that Knew Their Length,
of Terms that Knew Their Types, of Collections of Elements that were Heterogeneous, and about the
other magical beings of their home.  And they set out to build a natural environment for these
beings on the republic, namely the GADTs that we know and love, to remind them of home a little. And
their work was good and was admired by many.

A long time passed, and dispatches from another far-away land came to the republic, written by authors
whose names are now lost in the sea of anonymity, and I fear might forever remain so. And the
dispatches went something like this.

\rm

AUTHOR. ... The type system in my land of \lamprolog that I speak of is a subset of System
F$_\omega$ that should be familiar to you -- the simply typed lambda calculus, plus prenex
polymorphism, plus simple type constructors of the form `type * ... * type -> type`. There is a
`prop` sort for propositions, which is a normal type, but also a bit special: its terms are not just
values, but are also computations, activated when queried upon.

However, the language of this land has a distinguishing feature, called Ad-Hoc Polymorphism. You
see, the different rules that define a predicate in our language can *specialize* their type
variables. This can be used to define polymorphic predicates that behave differently for different
types, like this, where we are essentially doing a `typecase` and we choose a rule depending on the
*type* of the argument (as opposed to its value):

```
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

But alas! Is it not type specialization during pattern matching that is an essential feature of the
GADTs of your land?  Maybe that means that we can use Ad-Hoc Polymorphism not just to do `typecase`,
but also to work with GADTs in our land? Consider this! The venerable List that Knows Its Length:

```makam
zero : type. succ : type -> type.
vector : type -> type -> type.
vnil : vector A zero.
vcons : A -> vector A N -> vector A (succ N).
```

And now for the essential `vmap`:

```makam
vmap : [N] (A -> B -> prop) -> vector A N -> vector B N -> prop.
vmap P vnil vnil.
vmap P (vcons X XS) (vcons Y YS) :- P X Y, vmap P XS YS.
```

In each rule, the first argument already specializes the `N` type -- in the first rule to `zero`,
in the second, to `succ N`. And so erroneous rules that do not respect this specialization
would not be accepted as a well-typed saying in our language:

```
vmap P vnil (vcons X XS) :- ...
```

And we should note that in this usage of Ad-Hoc Polymorphism for GADTs, it is only the increased
precision of the statics that we care about. Dynamically, the rules for `vmap` can perform
normal term-level unification, and only look at the constructors `vnil` and `vcons` to see
whether each rule applies, rather than relying on the `typecase` aspects we spoke of before.

Coupling this with the binding constructs that I talked to you earlier about, we can build
new magical beings, like the *Bind that Knows Its Length*:

```makam
vbindmany : (Var: type) (N: type) (Body: type) -> type.
vbody : Body -> vbindmany Var zero Body.
vbind : (Var -> vbindmany Var N Body) -> vbindmany Var (succ N) Body.
```

(Whereby I am using notation of the Makam dialect in my definition of `vbind` that allows me to name
parameters, purely for the purposes of increased clarity.)

And the `openmany` version for `vbindmany`, where the rules are exactly as before:

```makam
vopenmany : [N] vbindmany Var N Body -> (vector Var N -> Body -> prop) -> prop.
vopenmany (vbody Body) Q :- Q vnil Body.
vopenmany (vbind F) Q :-
  (x:A -> vopenmany (F x) (fun xs => Q (vcons x xs))).
```

We can also showcase the *Accurate Encoding of the Letrec*:

```makam
vletrec : vbindmany term N (vector term N * term) -> term.
```

And that is the way that the land of \lamprolog supports GADTs, without needing the addition
of any feature, all thanks to the existing support for Ad-Hoc Polymorphism.

\identDialog

<!--
```makam
vapplymany : [N] vbindmany Var N Body -> vector Var N -> Body -> prop.
vapplymany (vbody Body) vnil Body.
vapplymany (vbind F) (vcons X XS) Body :- vapplymany (F X) XS Body.

vassumemany : [N] (A -> B -> prop) -> vector A N -> vector B N -> prop -> prop.
vassumemany P vnil vnil Q :- Q.
vassumemany P (vcons X XS) (vcons Y YS) Q :- (P X Y -> vassumemany P XS YS Q).

typeof (vletrec XS_DefsBody) T' :-
  vopenmany XS_DefsBody (pfun [XS Defs Body] XS (Defs, Body) =>
    vassumemany typeof XS TS (vmap typeof Defs TS),
    vassumemany typeof XS TS (typeof Body T')).

typeof (vletrec (vbind (fun f => vbody (vcons (lam T (fun x => app f (app f x))) vnil, f)))) T' ?
>> Yes:
>> T' := arrow T T,
>> T := T.
```
-->

TODO. \textcolor{red}{This is where I am! Haven't finished revising from here on.}

<!--
```makam
dbind : type -> type -> type -> type.
dbindbase : B -> dbind A unit B.
dbindnext : (A -> dbind A T B) -> dbind A (A * T) B.

subst : type -> type -> type.
nil : subst A unit.  cons : A -> subst A T -> subst A (A * T).

intromany : [T] dbind A T B -> (subst A T -> prop) -> prop.
applymany : [T] dbind A T B -> subst A T -> B -> prop.
openmany : [T] dbind A T B -> (subst A T -> B -> prop) -> prop.
assumemany : [T T'] (A -> B -> prop) -> subst A T -> subst B T' -> prop -> prop.
map : [T T'] (A -> B -> prop) -> subst A T -> subst B T' -> prop.

intromany (dbindbase F) P :- P [].
intromany (dbindnext F) P :- (x:A -> intromany (F x) (pfun t => P (x :: t))).

applymany (dbindbase Body) [] Body.
applymany (dbindnext F) (X :: XS) Body :- applymany (F X) XS Body.

openmany F P :-
  intromany F (pfun xs => [Body] applymany F xs Body, P xs Body).

assumemany P [] [] Q :- Q.
assumemany P (X :: XS) (Y :: YS) Q :- (P X Y -> assumemany P XS YS Q).

map P [] [].
map P (X :: XS) (Y :: YS) :- P X Y, map P XS YS.

letrec : dbind term T (subst term T * term) -> term.
typeof (letrec XS_DefsBody) T' :-
  openmany XS_DefsBody (pfun xs defsbody => [Defs Body]
    eq defsbody (Defs, Body),
    assumemany typeof xs TS (map typeof Defs TS),
    assumemany typeof xs TS (typeof Body T')).
```
-->

STUDENT. I see. Say, can we use the same dependency trick to do patterns?

ADVISOR. We should be able to... the linearity is going to be a bit tricky, but I am
fairly confident that having explicit support in our metalanguage just for single-variable
binding is enough to model most complicated forms of binding, when we also make use of
polymorphism and GADTs.

STUDENT. Makes sense. Well, I think I have an idea for patterns: we can have a type
argument to keep track of what variables they introduce. Since within a pattern we can
only refer to a variable once... no actual binding needs to take place. But we can use the type argument to bind the right number of pattern variables into the body of a branch.

ADVISOR. That is true.... One way I think about binding is that it is just a way to
introduce a notion of sharing into abstract syntax trees, so that we can refer to the same thing a number of times. And you're right that for patterns, the sharing happens from the side of the pattern into the branch body, not within the pattern itself.

STUDENT. Though there is some of that in dependent pattern matching, where you can reuse a
pattern variable and an exact matching takes place rather than unification....

ADVISOR. ...Right. But let's not worry about that right now; let's just do simple
patterns. So at the top level, a pattern will just have a single "tuple type" argument
with the variables it used. I am thinking that for sub-patterns, we will need two
arguments. One for all the variables that *can* be used, initially matching the type
argument of the top-level pattern; another argument, for the variables that
*remain* to be used after this sub-pattern is traversed.

STUDENT. I don't get that yet. Wait, let me first add natural numbers as a base type so
that we have a simple example.

```makam
nat : typ. zero : term. succ : term -> term.
typeof zero nat. typeof (succ N) nat :- typeof N nat.
eval zero zero. eval (succ E) (succ V) :- eval E V.
```

ADVISOR. Good idea. OK, so here's what I meant:

```makam
patt : type -> type -> type.
patt_var : patt (term * T) T.
patt_zero : patt T T.
patt_succ : patt T T' -> patt T T'.
```

STUDENT. Hmm. So, you said the first argument is what variables are "available" when we go
into the sub-pattern, second is what we're "left with"... so in the variable case, we "use
up" one variable. In the zero case, we don't use any. And for successors, we just
propagate the variables.

ADVISOR. Exactly. Could you do tuples?

STUDENT. Let me see, I think I'll need a helper type for multiple patterns....

```makam
pattlist : type -> type -> type.
nil : pattlist T T.
cons : patt T1 T2 -> pattlist T2 T3 -> pattlist T1 T3.
patt_tuple : pattlist T T' -> patt T T'.
```

ADVISOR. Exactly! And here's an interesting one: wildcards.

```makam
patt_wild : patt T T.
```

STUDENT. Oh, because that does not really introduce any pattern variables that we can
use. So if I understand this correctly, top-level patterns should always use up all their variables -- they should end with the second argument being `unit`, right?

ADVISOR. Exactly, so this should be fine for a single-branch pattern-match construct:

```makam
case_or_else : term -> patt T unit -> dbind term T term -> term -> term.
```

STUDENT. Let me parse that... the first argument is the scrutinee, the second is the
pattern... the third is the branch body, with the pattern variables introduced. Oh, and
the last argument is the `else` case.

ADVISOR. Right. And I think something like this should work for the typing judgment. Let
me write a few cases.

```makam
typeof : [T T' Ttyp T'typ] patt T T' -> subst typ T'typ -> subst typ Ttyp -> typ -> prop.
typeof patt_var S' (cons T S') T.
typeof patt_wild S S T.
typeof patt_zero S S nat.
typeof (patt_succ P) S' S nat :- typeof P S' S nat.
```

STUDENT. I see, so given a pattern and the types of the variables following the
sub-pattern, we produce the types of all the variables and the type of the pattern
itself. Makes sense. I'll do tuples:

```makam
typeof : [T T' Ttyp T'typ]
  pattlist T T' -> subst typ T'typ -> subst typ Ttyp -> list typ -> prop.
typeof (patt_tuple PS) S' S (product TS) :- typeof PS S' S TS.
typeof [] S S [].
typeof (P :: PS) S3 S1 (T :: TS) :- typeof PS S3 S2 TS, typeof P S2 S1 T.
```

ADVISOR. Looks good. Can you do the typing rule for the case statement?

STUDENT. How does this look?

```makam
typeof (case_or_else Scrutinee Pattern Body Else) T' :-
  typeof Scrutinee T,
  typeof Pattern nil TS T,
  openmany Body (pfun xs body => assumemany typeof xs TS (typeof body T')),
  typeof Else T'.
```

ADVISOR. That's great! This was a little tricky, but still, not too bad. Actually, I know
of one thing that is surprisingly simple to do: the evaluation rule. We just have to
convert a pattern into a term, where we replace the pattern variables with *meta-level*
unification variables -- then we can just reuse meta-level unification to do the actual
pattern match!

STUDENT. Oh, that would be nice. So not only do we get variable substitutions for free, we
also get unification for free in some cases!

ADVISOR. Exactly. So something like this should work:

```makam
patt_to_term : [T T'] patt T T' -> term -> subst term T' -> subst term T -> prop.
patt_to_term patt_var X Subst (X :: Subst).
patt_to_term patt_wild _ Subst Subst.
patt_to_term patt_zero zero Subst Subst.
patt_to_term (patt_succ PN) (succ EN) Subst' Subst :- patt_to_term PN EN Subst' Subst.
```

STUDENT. I see, interesting! So in each rule we introduce the unification variables that
we need, like `X` for the variable case, and store them in the substitution that we will
use with the pattern body.

\begin{scenecomment}
(Our heroes also write down the rules for multiple patterns and tuples, which are
available in the unabridged version of this story.)
\end{scenecomment}

<!--
```makam
pattlist_to_termlist : [T T'] pattlist T T' -> list term -> subst term T' -> subst term T -> prop.

patt_to_term (patt_tuple PS) (tuple ES) Subst' Subst :-
  pattlist_to_termlist PS ES Subst' Subst.

pattlist_to_termlist [] [] Subst Subst.
pattlist_to_termlist (P :: PS) (T :: TS) Subst3 Subst1 :-
  pattlist_to_termlist PS TS Subst3 Subst2,
  patt_to_term P T Subst2 Subst1.
```
-->

ADVISOR. We should be good to write the evaluation rule now.

```makam
eval (case_or_else Scrutinee Pattern Body Else) V :-
  patt_to_term Pattern TermWithUnifvars [] Unifvars,
  if (eq Scrutinee TermWithUnifvars)  (* reuse unification from the meta-language *)
  then (applymany Body Unifvars Body', eval Body' V)
  else (eval Else V).
```

STUDENT. I see! So, if meta-level unification is successful, we have a match, and we
substitute the instantiations we found for the pattern variables into the body. But you
are using if-then-else? We haven't used that so far.

ADVISOR. Oh yes, I forgot to mention that. It behaves as follows: when there is at least
one way to prove the condition, it proceeds to the `then` branch, otherwise it goes to the
`else` branch. Pretty standard really. It is one thing that the Prolog cut statement, `!`,
is useful for, but cut introduces all sorts of trouble. \citet{kiselyov05backtracking} is
worth reading for alternatives to the cut statement and the semantics of
`if`-`then`-`else` and `not` in logic programming, and Makam follows that closely.

STUDENT. Noted in my to-read list. But let us try pattern matching out! How about
predecessors for natural numbers? I'll write a query that type-checks and evaluates a
couple of cases.

```makam
(eq _PRED (lam _ (fun n => case_or_else n
  (patt_succ patt_var) (dbindnext (fun pred => dbindbase pred))
  zero)),
 typeof _PRED T,
 eval (app _PRED zero) PRED0, eval (app _PRED (succ (succ zero))) PRED2) ?
>> Yes:
>> T := arrow nat nat, PRED0 := zero, PRED2 := succ zero.
```

ADVISOR. Seems to be working fine!
