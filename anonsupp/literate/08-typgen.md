# Where our heroes implement type generalization, tying loose ends

<!--
```makam
%use "06-synonyms".
```
-->

\begin{verse}
``We promised we'll do Hindley-Milner, we don't want you to be sad. \\
This paper is coming to an end soon, and it wasn't all that bad. \\
\hspace{1em}\vspace{-0.5em} \\
We'll gather all unification variables, using structural recursion. \\
And if you haven't guessed it yet, we'll use some term reflection.''
\end{verse}

STUDENT. I have an idea for implementing type generalization for polymorphic `let` in the style of \citet{damas1984type,hindley1969principal,milner1978theory}.
I remember the typing rule looks like this:

\vspace{-1.2em}
\begin{mathpar}
\inferrule{\Gamma \vdash e : \tau \\ \vec{a} = \text{fv}(\tau) - \text{fv}(\Gamma) \\ \Gamma, x : \forall \vec{a}.\tau \vdash e' : \tau'}{\Gamma \vdash \text{let} \; x = e \; \text{in} \; e' : \tau'}
\end{mathpar}

ADVISOR. Right, and we don't have any side-effectful operations, so, no need for a value
restriction. Let's assume a predicate for generalizing the type, for now; the rest of the rule is easy:

```makam
generalize : typ -> typ -> prop.
let : term -> (term -> term) -> term.
typeof (let E F) T' :-
  typeof E T, generalize T Tgen, (x:term -> typeof x Tgen -> typeof (F x) T').
```

STUDENT. Right, so for generalization, based on the typing rule, we need the following ingredients:

- something that picks out free variables from a type -- or, in our setting, uninstantiated unification variables
- something that picks out free variables from the local context
- a way to turn something that includes unification variables into a `forall` type

\noindent
Those look like things that we should be able to do with our generic recursion and with the
reflective predicates we've been using!

ADVISOR. Indeed! So, I've done this before, and I need to leave for home soon, so bear with me
for a bit. There's this generic operation in the Makam standard library, called
`generic.fold`. It is quite similar to `structural_recursion`, but it does a fold through
a term, carrying an accumulator through. Pretty standard, really, and its code is similar to what
we did already. I'll use it to define a predicate that returns *one* unification
variable of the right type from a term, if at least one exists.

```makam
findunif : [A B] option B -> A -> option B -> prop.
findunif (some X) _ (some X).
findunif none (X : B) (some (X : B)) :- refl.isunif X.
findunif In X Out :- generic.fold findunif In X Out.
findunif : [A B] A -> B -> prop.  findunif T X :- findunif none T (some X).
```

STUDENT. Oh, the second rule is the important one -- it will only match when we encounter a unification
variable of the same type as the one we require, thanks to type specialization.

ADVISOR. Exactly. Now we add a predicate that, given a specific unification variable and a
specific term, replaces its occurrences with the term. I'll show you later why this
operation is necessary. Here I'll need another reflective predicate, `refl.sameunif`, that
succeeds when its two arguments are the same exact unification variable; `eq` would just
unify them, which is not what we want.

```makam
replaceunif : [A B] A -> A -> B -> B -> prop.
replaceunif Which ToWhat Where Result :- refl.isunif Where,
  if (refl.sameunif Which Where) then (eq (dyn Result) (dyn ToWhat))
  else (eq Result Where).
replaceunif Which ToWhat Where Result :- not(refl.isunif Where),
  structural_recursion (replaceunif Which ToWhat) Where Result.
```

ADVISOR. And last, we'll need an auxiliary predicate that tells us whether a unification
variable exists within a term. You can do that yourself; it's similar to the above.

STUDENT. Yes, I think I know how to do that.
```makam
hasunif : [A B] B -> bool -> A -> bool -> prop.
hasunif _ true _ true.
hasunif X false Y true :- refl.sameunif X Y.
hasunif X In Y Out :- generic.fold (hasunif X) In Y Out.
hasunif : [A B] A -> B -> prop. hasunif Term Var :- hasunif Var false Term true.
```

ADVISOR. OK, we are now mostly ready to implement `generalize`. We'll do this recursively. The
base case is when there are no unification variables within a type left:
```makam
generalize T T :- not(findunif T X).
```

STUDENT. Ah, I see what you are getting at. For the recursive case, we will pick out the first
unification variable that we come upon using `findunif`. We will generalize over it using `replaceunif`
and then proceed to the rest. But don't we have to skip over the unification variables that are in
the $\Gamma$ environment?

ADVISOR. Well, that's the last hurdle. Let's assume a predicate that gives us all the
types in the environment, and write the recursive case down:

```makam
get_types_in_environment : [A] A -> prop.
generalize T Res :- 
  findunif T Var, get_types_in_environment GammaTypes,
  (x:typ -> (replaceunif Var x T (T' x), generalize (T' x) (T'' x))),
  if (hasunif GammaTypes Var) then (eq Res (T'' Var)) else (eq Res (forall T'')).
```

STUDENT. Oh, clever. But what should `get_types_in_environment` be? Don't we have to go
back and thread a list of types through our `typeof` predicate, every time we introduce a
new `typeof x T ->` assumption?

ADVISOR. Well, we came this far without rewriting our rules, so it's a shame to do that now!
Maybe we'll be excused to use yet another reflective predicate that does what we
want? There is a way to get a list of all the local assumptions for the `typeof` predicate; it
turns out that all the rules and connectives are normal λProlog terms like any other,
so there's not really much magic to it. And those assumptions will include just the
types in $\Gamma$....

```makam
get_types_in_environment Assumptions :-
  refl.assume_get (typeof : term -> typ -> prop) Assumptions.
```

STUDENT. Wait. It can't be.
```makam
typeof (let (lam _ (fun x => let x (fun y => y))) (fun id => id)) T ?
>> Yes:
>> T := forall (fun a => arrow a a)
```

ADVISOR. And yet, it can.

<!--
(Just checking the issue where we don't remove all unification variables in the context -- this
is a hack, if we need to do this we can show the above in two steps instead:)

```makam
(get_types_in_environment [] ->
  typeof (let (lam _ (fun x => let x (fun y => y)))
            (fun z => z)) T) ?
>> Yes:
>> T := forall (fun a => arrow a (forall (fun b => b)))
```
-->