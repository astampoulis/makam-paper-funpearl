# Where our heroes get out of the bind using ad-hoc polymorphism

<!--
```makam
%use "02-binding-forms".
```
-->

STUDENT. No dependent types... so what is the λProlog type system? Is it some version of
System F?

ADVISOR. It is a subset of System F$_\omega$ actually -- so, the simply typed lambda
calculus, plus prenex polymorphism, plus simple type constructors of the form `type ->
type -> ... -> type`. The `prop` sort of propositions is a bit special, since we can only
add rules to its inhabitants, but otherwise it is just a normal type.

STUDENT. I see. So, that is quite similar to base Haskell -- without the recent extensions
with kind definitions \citep{yorgey2012giving} or Type-in-Type \citep{weirich2013system}
-- and it is still possible to have dependently typed datatypes there through GADTs.

ADVISOR. How so?

STUDENT. Well, you can use empty datatypes to encode type-level data, by exploiting the
type parameters... For example, you could do type-level natural numbers with `NatZ :: *` and `NatS :: * -> *` and then use them as a "dependent" index for vectors.

<!--
```haskell
data NatZ
data NatS a
data Vector n a =
  VNil :: Vector NatZ a
  VCons :: a -> Vector n a -> Vector (NatS a)
```
-->

ADVISOR. Oh, right, I forgot about that. Well, we could do the same thing in Makam then:

```makam
natZ : type.
natS : type -> type.

vector : type -> type -> type.
vnil : vector natZ A.
vcons : A -> vector N A -> vector (natS N) A.
```

STUDENT. Oh, so λProlog supports GADTs? Pattern matching propagates type information and
everything?

ADVISOR. Well, it does not work quite the same way, but yes. The way it works in λProlog
is through *ad-hoc polymorphism*: polymorphic type variables can be unified at *runtime*
rather than at type-checking time. So before performing term-level unification, type-level
unification is done, so uninstantiated type variables can be further determined; we can
thus "learn" and propagete extra type information at runtime. So we could do `map` for vectors as follows:

```makam
vmap : [N] (A -> B -> prop) -> vector N A -> vector N B -> prop.
vmap P vnil vnil.
vmap P (vcons X XS) (vcons Y YS) :- P X Y, vmap P XS YS.
```

STUDENT. Interesting. The `[N]` notation in the type of `vmap`, what is that?

ADVISOR. Well, type arguments for propositions are parametric by default, so that says
that `N` is ad-hoc polymorphic -- rules can specialize it further. And the reason for that
is that we are used to type arguments being parametric, and we can catch some errors that
way -- for example this erroneous `fold` is still well-typed if the type arguments are
ad-hoc:

```
foldl : (B -> A -> B -> prop) -> B -> list A -> B -> prop.
foldl P S nil S.
foldl P S (cons HD TL) S'' <- P HD S S', foldl P S' TL S''.
```

STUDENT. Oh, the `HD` argument in the call to `P` should be second instead of first -- and
this definition would only work when `A` and `B` are the same?

ADVISOR. Precisely, but we would only find out at runtime, if it was called with `A` and
`B` being different.

STUDENT. I see. So type-level unification, is that a standard λProlog feature, or just
Makam?

ADVISOR. It's hard to say. I think this was part of the original design by
\citet{miller1988overview}, but I have not come upon any examples that actively use it so
far -- for example, the book by \citet{miller2012programming} hardly mentions the feature,
and the standard λProlog implementation, Teyjus \citet{nadathur1999system}, has a few
issues related to polymorphic types that have not allowed me to test this there.

STUDENT. Well let's see if it is actually useful for what we were trying to do. Maybe we
can use this feature for a better encoding of `letrec`? We could do the `vector`
equivalent of `bindmany`, carrying a type argument for the number of binders, so that we
can reuse that for a `vector` of definitions:

```makam
dbind : type -> type -> type -> type. 
dbindbase : B -> dbind A natZ B.
dbindnext : (A -> dbind A N B) -> dbind A (natS N) B.
letrec : dbind term N (vector N term * term) -> term.
```

ADVISOR. That looks good, but I do not like this natural number trick -- if we could
define a new `nat` kind and specify that in the type of `dbind`, it would be fine, but as
it stands... Well, here's an idea. The "dependent" index could be the type of `n`-tuples
of variables, rather than `n` itself:

```makam
dbind : type -> type -> type -> type.
dbindbase : B -> dbind A unit B.
dbindnext : (A -> dbind A T B) -> dbind A (A * T) B.
```

STUDENT. That should work. Should we also define the equivalent of `vector` with the same
type of index?

ADVISOR. Sure. We could just use the tuple type `T` and do pattern-matching on whether
it's equal to `A * B` or `unit`, but constructor-based pattern matching reads much
better. Let's call it `subst` for substitutions:

```makam
subst : type -> type -> type.
nil : subst A unit.
cons : A -> subst A T -> subst A (A * T).
```

STUDENT. We are already using `nil` and `cons` for lists, should we call the constructors
something else?

ADVISOR. No, this works fine, and we can reuse the syntactic sugar for them. Makam allows
overloading for all constants, it takes statically-known type information into account for
resolving variables and disambiguating between them. Sometimes you have to do a type
ascription, but I find it works nicely in most cases.

STUDENT. I see. So let me try my hand at writing the helper predicates that we'll need for `dbind` and `subst`. How do these look?

```makam
intromany : [T] dbind A T B -> (subst A T -> prop) -> prop.
applymany : [T] dbind A T B -> subst A T -> B -> prop.
openmany : [T] dbind A T B -> (subst A T -> B -> prop) -> prop.
assumemany : [T T'] (A -> B -> prop) -> subst A T -> subst B T' -> prop -> prop.
map : [T T'] (A -> B -> prop) -> subst A T -> subst B T' -> prop.
```

ADVISOR. These look fine -- they're quite similar to the ones for `bindmany`. `assumemany`
and `map` do not really capture the relationship between `T` and `T'`, which are the same
tuples save for `A`s being replaced by `B`s... but we don't have to complicate this
further, I am sure we could capture that if needed with another dependent construction.

STUDENT. That's what I was thinking too. Let me see, I think most of these are almost
identical to what we had before.

```makam
intromany (dbindbase F) P :- P [].
intromany (dbindnext F) P :- (x:A -> intromany (F x) (pfun t => P (x :: t))).
...
```

\begin{scenecomment}
(Our heroes copy paste the code from before for the rest of the predicates,
changing `bindbase` to `dbindbase` and `bindnext` to `dbindnext`.)
\end{scenecomment}
<!--
```makam
applymany (dbindbase Body) [] Body.
applymany (dbindnext F) (X :: XS) Body :- applymany (F X) XS Body.

openmany F P :-
  intromany F (pfun xs => [Body] applymany F xs Body, P xs Body).

assumemany P [] [] Q :- Q.
assumemany P (X :: XS) (Y :: YS) Q :- (P X Y -> assumemany P XS YS Q).

map P [] [].
map P (X :: XS) (Y :: YS) :- P X Y, map P XS YS.
```
-->

ADVISOR. Alright, I think we should be able to do `letrec` now!
```makam
letrec : dbind term T (subst term T * term) -> term.
typeof (letrec XS_DefsBody) T' :-
  openmany XS_DefsBody (pfun xs defsbody => [Defs Body]
    eq defsbody (Defs, Body),
    assumemany typeof xs TS (map typeof Defs TS),
    assumemany typeof xs TS (typeof Body T')
  ).
```

STUDENT. What is `eq`?

ADVISOR. Oh, that's just to force unification with `(Defs, Body)` and get the elements of
the tuple -- there's no destructuring `pfun`. `eq` is just defined as:

```
eq : A -> A -> prop.
eq X X.
```

STUDENT. I see. Say, can we use the same trick to do patterns?

ADVISOR. We should be able to... the linearity is going to be a bit tricky, but I am
fairly confident that having explicit support in our metalanguage just for single-variable
binding is enough to model most complicated forms of binding, when we also make use of
polymorphism and GADTs.

STUDENT. Makes sense. Well, I think I have an idea for patterns: we can have a type
argument to keep track of what variables they introduce. Since within a pattern we can
only refer to a variable once... no actual binding needs to take place. But we can use the type argument to bind the right number of pattern variables into the body of a branch.

ADVISOR. That is true... One way I think about binding is that it is just a way to
introduce a notion of sharing into abstract syntax trees, so that we can refer to the same thing a number of times. And you're right that for patterns, the sharing happens from the side of the pattern into the branch body, not within the pattern itself.

STUDENT. Though there is some of that in dependent pattern matching, where you can reuse a
pattern variable and an exact matching takes place rather than unification...

ADVISOR. ...Right. But let's not worry about that right now, let's just do simple
patterns. So at the top-level, a pattern will just have a single "tuple type" argument
with the variables it used. I am thinking that for sub-patterns, we will need two
arguments. One for all the variables that *can* be used, initially matching the type
argument of the top-level pattern; another argument, for the variables that
*remain* to be used after this sub-pattern is traversed.

STUDENT. I don't get that yet. Wait, let me first add natural numbers as a base type so
that we have a simple example.

```makam
nat : typ. zero : term. succ : term -> term.
typeof zero nat.
typeof (succ N) nat :- typeof N nat.
eval zero zero.
eval (succ E) (succ V) :- eval E V.
```

ADVISOR. Good idea. OK, so here's what I meant:

```makam
patt : type -> type -> type.
patt_var : patt (term * T) T.
patt_zero : patt T T.
patt_succ : patt T T' -> patt T T'.
```

STUDENT. Hmm. So, you said the first argument is what variables are "available" when we go
into the sub-pattern, second is what we're "left with"... so the variable case, we "use
up" one variable, in the zero case, we don't use any. And for successors, we just
propagate the variables.

ADVISOR. Exactly. Could you do tuples?

STUDENT. Let me see, I think I'll need a helper type for multiple patterns...

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

ADVISOR. Exactly, so this should be fine for a single-branch pattern match construct:

```makam
case_or_else : term -> patt T unit -> dbind term T term -> term -> term.
```

STUDENT. Let me parse that... the first argument is the scrutinee, the second is the
pattern... the third is the branch body, with the pattern variables introduced. Oh, and
the last argument is the `else` case.

ADVISOR. Right. And I think something like this should work for the typing judgement. Let
me write a few cases.

```makam
typeof : [T T' Ttyp T'typ] patt T T' -> subst typ T'typ -> subst typ Ttyp -> typ -> prop.
typeof patt_var S' (cons T S') T.
typeof patt_wild S S T.
typeof patt_zero S S nat.
typeof (patt_succ P) S' S nat :- typeof P S' S nat.
```

STUDENT. I see, so given a pattern and the types of the variables following the
sub-pattern, we produce the types of all the variables, and the type of the pattern
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

ADVISOR. That's great! This was a little tricky, but still, not too bad. Actually I know
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
is useful for, but it's better to avoid introducing `!`. \citet{kiselyov05backtracking} is
worth reading for alternatives to the cut statement and the semantics of if-then-else in
logic programming.

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
>> T := arrow nat nat
>> PRED0 := zero
>> PRED2 := succ zero
```

ADVISOR. Seems to be working fine!
