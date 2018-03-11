# Where our heroes add parentheses and discover how to do multiple binding

<!--
```makam
%use "02-stlc.md".
tests : testsuite. %testsuite tests.
```
-->

STUDENT. Still, I feel like we've been playing to the strengths of λProlog.... Yes, single-variable
binding, substitutions, and so on work nicely, but how about any other form of binding? Say, binding
multiple variables at the same time? We are definitely going to need that for the language we have
in mind. I was under the impression that HOAS encodings do not work for that -- for example, I was
reading \citet{keuchel2016needle} recently and I remember reading something to that end.

ADVISOR. That's not really true; having first-class support for single-variable binders should be
enough. But let's try it out, maybe adding multiple-argument functions for example -- I mean
uncurried ones. Want to give it a try?

STUDENT. Let me see. We want the terms to look roughly like this:
```
lammany (fun x => fun y => tuple [y, x])
```

For the type of `lammany`, I want to write something like this, but I know this is wrong.

```
lammany : (list term -> term) -> term.
```

ADVISOR. Yes, that doesn't quite work. It would introduce a fresh variable for `list`s,
not a number of fresh variables for `term`s. HOAS functions are parametric, too, which
means we cannot even get to the potential elements of the fresh `list` inside the `term`.

STUDENT. Right. So I don't know, instead we want to use a type that stands for `term ->
term`, `term -> term -> term`, and so on. Can we write `term -> ... -> term`?

ADVISOR. Well, not quite, but we have already defined something similar, a type that
roughly stands for `term * ... * term`, and we did not need anything special
for that...

STUDENT. You mean the `list` type?

ADVISOR. Exactly. What do you think about this definition?

```makam-noeval
bindmanyterms : type.
bindnil : term -> bindmanyterms.
bindcons : (term -> bindmanyterms) -> bindmanyterms.
```

STUDENT. Hmm. That looks quite similar to lists; the parentheses in `cons` are
different. `nil` gets an extra `term` argument, too...

ADVISOR. Yes... So what is happening here is that `bindcons` takes a single argument,
introducing a binder; and `bindnil` is when we get to the body and don't need any more
binders. Maybe we should name them accordingly.

STUDENT. Right, and could we generalize their types? Maybe that will help me get a better
grasp of it. How is this?

```makam
bindmany : type -> type -> type.
body : Body -> bindmany Variable Body.
bind : (Variable -> bindmany Variable Body) -> bindmany Variable Body.
```

ADVISOR. This looks great! That is exactly what's in the Makam standard library actually. And
we can now define `lammany` using it -- and our example term from before.

```makam-noeval
lammany : bindmany term term -> term.
lammany (bind (fun x => bind (fun y => body (tuple [y,x]))))
```

<!--
```makam
lammany : bindmany term term -> term.
refl.typstring (lammany (bind (fun x => bind (fun y => body (tuple [y,x]))))) "term" ?
>> Yes.
```
-->

STUDENT. I see. That is an interesting datatype. Is there some reference about it?

ADVISOR. Not that I know of, at least where it is called out as a reusable datatype -- though the
construction is definitely part of PL folklore. After I started using this in Makam, I noticed
similar constructions in the wild, for example in MTac \citep{ziliani2013mtac}, for parametric HOAS
implementation of telescopes in Coq.

STUDENT. Interesting. So how do we work with `bindmany`? What's the typing rule like?

ADVISOR. The rule is written like this, and I'll explain what goes into it:

```makam-noeval
arrowmany : list typ -> typ -> typ.
typeof (lammany F) (arrowmany TS T) :-
  openmany F (fun xs body =>
    assumemany typeof xs TS (typeof body T)).
```

STUDENT. Let me see if I can read this... `openmany` somehow gives you fresh variables `xs` for the
binders, and the `body` of the `lammany`; and then the `assumemany typeof` part is what corresponds
to extending the $\Gamma$ context with multiple typing assumptions?

ADVISOR. Yes, and then we typecheck the `body` in that local context that includes the fresh
variables and the typing assumptions. But let's do one step at a time. `openmany` is simple; we
iterate through the nested binders, introducing one fresh variable at a time. We also substitute
each bound variable for the current fresh variable, so that when we get to the body, it only uses
the fresh variables we introduced.

```makam
openmany : bindmany A B -> (list A -> B -> prop) -> prop.
openmany (body Body) Q :- Q [] Body.
openmany (bind F) Q :-
  (x:A -> openmany (F x) (fun xs => Q (x :: xs))).
```

STUDENT. I see. I guess `assumemany` is similar, introducing one assumption at a time?

```makam
assumemany : (A -> B -> prop) -> list A -> list B -> prop -> prop.
assumemany P [] [] Q :- Q.
assumemany P (X :: XS) (T :: TS) Q :- (P X T -> assumemany P XS TS Q).
```

<!--
```makam
arrowmany : list typ -> typ -> typ.
typeof (lammany F) (arrowmany TS T) :-
  openmany F (fun xs body =>
    assumemany typeof xs TS (typeof body T)).
```
-->

<!--
TODO. Figure out where to place this.
```makam
applymany : bindmany A B -> list A -> B -> prop.
applymany (body B) [] B.
applymany (bind F) (X :: XS) B :-
  applymany (F X) XS B.
```
-->

ADVISOR. Yes, exactly! Just a note though -- \lamprolog typically does not allow the definition of `assumemany`, where a non-concrete predicate like `P X Y` is used as an assumption, because of logical reasons. Makam is more lax, and so is ELPI, another recent \lamprolog implementation, and allows this form statically, though there are instantiations of `P` that will fail at run-time.

STUDENT. I see. But we could just manually inline `assumemany typeof` instead, so that's not a big problem, just more verbose. But can I try our typing rule out?

```makam
typeof (lammany (bind (fun x => bind (fun y => body (tuple [y, x]))))) T ?
>> Yes:
>> T := arrowmany [T1, T2] (product [T2, T1]).
```

Great, I think I got the hang of this. We could definitely add a multiple-argument application
construct `appmany` or define the rules for `eval` for these. But that would be easy; we can do it
later. Something that worries me, though -- all these fancy higher-order abstract binders, how do we
... make them concrete? Say, how do we print them?

ADVISOR. That's actually quite easy. We just add a concrete name to them. A plain old `string`. Our
typing rules etc. do not care about it, but we could use it for parsing concrete syntax into our
abstract binding syntax, or for pretty-printing.... Let's not get into that for the time being, but
let's just say that we could have defined `bind` with an extra `string` argument, representing the
concrete name; and then `openmany` would just ignore it.

```makam-noeval
bind : string -> (Var -> bindmany Var Body) -> bindmany Var Body.
```

STUDENT. Interesting. I would like to see more about this, but maybe some other time. I
thought of another thing that could be challenging: mutually recursive `let rec`s?

ADVISOR. Sure. Let's take this term for example:

```
let rec f = f_def and g = g_def in body
```

If we write this in a way where the binding structure is explicit, we would bind
`f` and `g` simultaneously, and then write the definitions and the body in that scope:

```
letrec (fun f => fun g => ([f_def, g_def], body))
```

STUDENT. I think I know how to do this then! How does this look?

```makam
letrec : bindmany term (list term * term) -> term.
```

ADVISOR. Exactly! Want to try writing the typing rules?

STUDENT. Maybe something like this?

```makam-noeval
typeof (letrec XS_DefsBody) T' :-
  openmany XS_DefsBody (fun xs (Defs, Body) =>
    assumemany typeof xs TS (map typeof Defs TS),
    assumemany typeof xs TS (typeof Body T')).
```

ADVISOR. Almost! The parser isn't clever enough to tell that the predicate argument to `openmany`
is, in fact, a predicate, so we can't use the normal predicate syntax for it. We can use the
syntactic form `pfun` for writing anonymous predicates instead. Since this will be a
predicate, you are also able to destructure parameters like you do here -- that doesn't work for
normal functions in the general case, since they need to treat arguments parametrically.
And there is an actual issue here: could you guess what it is? It has to do with which free variables
a unification variable is allowed to capture.

STUDENT. Not really, but might have something to do with the fresh variables that `openmany` introduces?

ADVISOR. Yes. See, a unification variable is allowed to capture all the free variables in scope at the
point where it is introduced. By default, all unification variables used in a rule get introduced when we
check whether the rule fires. But here we need to say explicitly that certain unification variables need to be
introduced when `openmany` gets to use the `pfun` argument, and has therefore introduced all the needed fresh variables.
So we have to write the rule like this:

```makam
typeof (letrec XS_DefsBody) T' :-
  openmany XS_DefsBody (pfun [XS Defs Body] XS (Defs, Body) =>
    assumemany typeof XS TS (map typeof Defs TS),
    assumemany typeof XS TS (typeof Body T')).
```
<!--
```makam
typeof (letrec (bind (fun f => body ([lam T (fun x => app f (app f x))], f)))) T' ?
>> Yes:
>> T' := arrow T T,
>> T := T.
```
-->

STUDENT. Ah, I see. So the `[XS Defs Body]` notation is like existential quantification then.

ADVISOR. Exactly.

STUDENT. One thing I noticed with our representation of `letrec` is that we have to be careful so
that the number of binders matches the number of definitions we give. Our typing rules disallow
that, but I wonder if there's a way to have a more accurate representation for `letrec` that
requires that to be the case?

ADVISOR. Funny you should ask that... Let me tell you a story.