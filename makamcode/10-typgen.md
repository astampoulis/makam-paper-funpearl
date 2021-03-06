# In which our hero Roza implements type generalization, tying loose ends

<!--
```makam
%use "09-metaml.md".
tests: testsuite. %testsuite tests.
```
-->

\begin{versy}
``We mentioned Hindley-Milner / we don't want you to be sad. \\
This paper's going to end soon / and it wasn't all that bad. \\
\hspace{1em}\vspace{-0.5em} \\
(Before we get to that, though / it's time to take a break. \\
If taksims seem monotonous / then put on some Nick Drake.) \\
\hspace{1em}\vspace{-0.5em} \\
We'll gather unif-variables / with structural recursion \\
and if you haven't guessed it yet / we'll get to use reflection.''
\end{versy}

ADVISOR. Let me now show you how to implement type generalization for polymorphic `let` in the style of \citet{damas1984type,hindley1969principal,milner1978theory}. I've done this before\footnote{There is existing work that has considered the problem of ML type generalization
in the \lamprolog setting \citep{typgen-lamprolog-1,typgen-lamprolog-2}. Our presentation here follows a different approach based on reflective and generic predicates.}, and I need to leave for home soon, so bear with me
for a bit. The gist will be to reuse the unification support of our metalanguage,
capturing the *metalevel unification variables* and generalizing over them. That way we will
have a very short implementation, and we won't have to do a deep embedding of unification!

STUDENT. So -- you're saying that in \lamprolog, other than reusing the metalevel function type
for implementing object-level substitution, we can also reuse metalevel unification for the
object level as well.

\identNormal

ADVISOR. Exactly! First of all, the typing rule for a generalizing let looks like this:

\vspace{-1.2em}
\begin{mathpar}
\inferrule{\Gamma \vdash e : \tau \\ \vec{a} = \text{fv}(\tau) - \text{fv}(\Gamma) \\ \Gamma, x : \forall \vec{a}.\tau \vdash e' : \tau'}{\Gamma \vdash \text{let} \; x = e \; \text{in} \; e' : \tau'}
\end{mathpar}

We don't have any side-effectful operations, so there is no need for a value
restriction. Transcribing this to Makam is easy, if we assume a predicate for
generalizing the type, for now:

```makam
generalize : (Type: typ) (GeneralizedType: typ) -> prop.
let : term -> (term -> term) -> term.
```
\importantCodeblock{}
```makam
typeof (let E F) T' :-
  typeof E T, generalize T Tgen,
  (x:term -> typeof x Tgen -> typeof (F x) T').
```
\importantCodeblockEnd{}

Now, for generalization itself, we need the following ingredients based on the typing rule:

- something that picks out free variables from a type, standing for the $\text{fv}(\tau)$ part -- or, in our setting, this should really be read as uninstantiated unification variables. Those are the Makam-level unification variables that have not been forced to unify with concrete types because of the rest of the typing rules.
- something that picks out free variables from the local context: the $\text{fv}(\Gamma)$ part. Again, these are the uninstantiated unification variables rather than the free variables. In our case, the context $\Gamma$ is represented by the local `typeof` assumptions that our typing rules add, so we'll have to look at those somehow.
- a way to turn something that includes unification variables into a $\forall$ type, corresponding to the $\forall \vec{a}.\tau$ part. This essentially abstracts over a number of variables and uses them as the replacement for the unification variables inside $\tau$.

All of those look like things that we should be able to do with our generic recursion and with the
reflective predicates we've been using! However, to make the implementation simpler, we will
generalize over one variable at a time, instead of all at once -- but that should be entirely
equivalent to what's described in the typing rule.

First, we will define a `findunif` predicate that returns *one* unification variable *of the right
type* from a term, if at least one such variable exists. To implement it, we will make use of a
generic operation in the Makam standard library, called `generic_fold`. It is quite similar to
`structural_recursion`, but it does a fold through a term, carrying an accumulator through. Pretty
standard, really, and its code is similar to what we did already for `structural_recursion`, with no
new surprises.

<!--
```makam-stdlib
generic_fold : [A'] forall A (B -> A -> B -> prop) -> B -> A' -> B -> prop.

generic_fold F Acc X Acc when refl.isconst X.

generic_fold F Acc (X : A -> B) Acc' <-
  (x:A -> (instantiate F F', F' Acc (X x) Acc')).

polyrec_foldl : forall A (B -> A -> B -> prop) -> B -> list dyn -> B -> prop.
polyrec_foldl P S nil S.
polyrec_foldl P S (cons (dyn HD) TL) S'' <-
  forall.apply P S HD S',
  polyrec_foldl P S' TL S''.

generic_fold F Acc X Acc' when refl.isbaseterm X <-
  refl.headargs X HD Args,
  polyrec_foldl F Acc Args Acc'.
```
-->

```makam-stdlib
findunif_aux : [Any VarType]
  (Var: option VarType) (Current: Any) (Var': option VarType) -> prop.
findunif_aux (some Var) _ (some Var).
findunif_aux none (Current : CurrentType) (Result: option VarType) :-
  refl.isunif Current,
  if (dyn.eq Result (some Current)) then success
  else (eq Result none).
findunif_aux (In: option B) Current Out :-
  generic_fold @findunif_aux In Current Out.
findunif : [Any VarType] (Search: Any) (Found: VarType) -> prop.
findunif Search Found :- findunif_aux none Search (some Found).
```

Here, the second rule of `findunif_aux` is the important one -- it will only succeed when we
encounter a unification variable of the *same type* `VarType` as the one we require. This rule 
relies on the dynamic `typecase` aspect of the ad-hoc polymorphism in \lamprolog, making
use of the `dyn.eq` standard-library predicate, which has a lax typing:

```
dyn.eq : [A B] A -> B -> prop.
dyn.eq X X.
```

Though this predicate succeeds for the same case as the standard `eq` does (when its two arguments
are unifiable), the difference is that `dyn.eq` only forces the types `A` and `B` to be unified at
runtime, rather than statically, too. Otherwise, our rule would only apply when the type
`CurrentType` of the current unification variable we are visiting already matches the type that we
are searching for, `VarType`.

With `findunif` defined, we should already be able to find *one* (as opposed to all, as described above)
uninstantiated unification variable from a type. Here is an example of its use:

```
findunif (arrowmany TS T) (X: typ) ?
>> Yes:
>> X := T.
```

<!--
```makam
findunif (arrowmany TS T) (X: typ) ?
>> Yes:
>> X := T,
>> T := T,
>> TS := TS.
```
-->

Now we add a predicate `replaceunif` that, given a specific unification variable and a
specific term, replaces the variable's occurrences with the term. This will be needed as part of the
$\forall \vec{a}.\tau$ operation of the rule. Here I'll need another reflective predicate,
`refl.sameunif`, that succeeds when its two arguments are the same exact unification variable;
`eq` would just unify them, which is not what we want.

```makam-stdlib
replaceunif : [VarType Any]
  (Which: VarType) (ToWhat: VarType) (Where: Any) (Result: Any) -> prop.
replaceunif Which ToWhat Where ToWhat :-
  refl.isunif Where, refl.sameunif Which Where.
replaceunif Which ToWhat Where Where :-
  refl.isunif Where, not(refl.sameunif Which Where).
replaceunif Which ToWhat Where Result :- not(refl.isunif Where),
  structural_recursion @(replaceunif Which ToWhat) Where Result.
```

Last, we'll need an auxiliary predicate that tells us whether a unification variable exists within a
term. This is easy; it's similar to the above.

```makam-stdlib
hasunif_aux : [VarType Any] VarType -> bool -> Any -> bool -> prop.
hasunif_aux _ true _ true.
hasunif_aux X false Y true :- refl.sameunif X Y.
hasunif_aux X In Y Out :- generic_fold @(hasunif_aux X) In Y Out.

hasunif : [VarType Any] VarType -> Any -> prop.
hasunif Var Term :- hasunif_aux Var false Term true.
```

We are now mostly ready to implement `generalize`. We'll do this recursively. The base case is when there are no unification variables within a type left:

\importantCodeblock{}
```makam
generalize T T :- not(findunif T (X: typ)).
```
\importantCodeblockEnd{}

For the recursive case, we will pick out the first unification variable that we come upon using
`findunif`. We will generalize over it using `replaceunif` and then proceed to the rest.  Still,
there is a last hurdle: we have to skip over the unification variables that are in the $\Gamma$
environment. For the time being, let's assume a predicate that gives us all the types in the
environment, so we can write the recursive case down:

\importantCodeblock{}
```makam
get_types_in_environment : [A] A -> prop.
generalize T Res :-
  findunif T Var, get_types_in_environment GammaTypes,
  (x:typ -> (replaceunif Var x T (T' x), generalize (T' x) (T'' x))),
  if (hasunif Var GammaTypes) then (eq Res (T'' Var))
  else (eq Res (tforall T'')).
```
\importantCodeblockEnd{}

\identDialog

STUDENT. Oh, clever. But what should `get_types_in_environment` be? Don't we have to go
back and thread a list of types through our `typeof` predicate, to which we add a type `T` 
every time we introduce a new `typeof x T` assumption?

ADVISOR. Well, we came this far without significantly rewriting our rules, so it's a shame to do
that now!  Maybe we'll be excused to use yet another reflective predicate that does what we want?
There is a way to get a list of all the local assumptions for a predicate, through the
reflexive predicate `refl.assume_get`. It turns out that all the rules and connectives we
have been using are normal \lamprolog terms like any other, so there's not really
much magic to it. And those assumptions will include all the types in $\Gamma$....

\importantCodeblock{}
```makam
get_types_in_environment Assumptions :-
  refl.assume_get typeof Assumptions.
```
\importantCodeblockEnd{}

STUDENT. Wait. It can't be.
```makam
typeof (let (lam _ (fun x => let x (fun y => y))) (fun id => id)) T ?
>> Yes:
>> T := tforall (fun a => arrow a a).
```

ADVISOR. And yet, it can.

<!--
```makam
(* Simulate the naive rule where we don't remove all the unification variables that appear in
   the context: *)

(get_types_in_environment [] ->
  typeof (let (lam _ (fun x => let x (fun y => y)))
            (fun z => z)) T) ?
>> Yes:
>> T := tforall (fun a => arrow a (tforall (fun b => b))).
```
-->
