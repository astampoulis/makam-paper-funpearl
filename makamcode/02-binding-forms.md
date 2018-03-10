# Where our heroes add parentheses and discover how to do multiple binding

<!--
```makam
%use "01-base-language.md".
test02 : testsuite. %testsuite test02.
```
-->

STUDENT. Still, I feel like we've been playing to the strengths of λProlog.... Yes, single-variable
binding, substitutions, and so on work nicely, but how about any other form of binding? Say, binding
multiple variables at the same time? We are definitely going to need that for the language we have
in mind. I was under the impression that HOAS encodings do not work for such forms of binding -- for
example, I was reading \citet{keuchel2016needle} recently and I remember reading something like
that.

ADVISOR. That's not really true; having first-class support for single-variable binders should be enough, and I think this is well-understood. But let's try it out, maybe adding multiple-argument functions for
example -- I mean uncurried ones. Want to give it at try?

STUDENT. Let me see. Well, I want to write something like this, but I know this is wrong.

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

```makam
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

ADVISOR. This looks great! We have allowed binding zero variables, but that makes the
constructors nicer and will simplify our predicates too.

STUDENT. I see. That is an interesting datatype. Is there some reference about it?

ADVISOR. Not that I know of, at least where it is called out as a reusable datatype -- though the
construction is definitely part of PL folklore. After I started using this in Makam, I noticed
similar constructions in the wild, for example in MTac \citep{ziliani2013mtac}, for parametric HOAS
implementation of telescopes in Coq.

STUDENT. Interesting. So how do we work with `bindmany`? I know we can now define
`lammany` now, but how about the typing rule?

```makam
lammany : bindmany term term -> term.
```

ADVISOR. The rule will be like this, but I'll explain what goes into it:

```makam-noeval
arrowmany : list typ -> typ -> typ.
typeof (lammany F) (arrowmany TS T) :-
  openmany F (fun xs body =>
    assumemany typeof xs TS (typeof body T)).
```

STUDENT. Let me see if I can read this... `openmany` somehow gives you fresh variables `xs` for the binders, and the `body` of the `lammany`; and then the `assumemany typeof` part is what corresponds to extending the $\Gamma$ context with multiple typing assumptions?

ADVISOR. Yes, and then we typecheck the `body` in that local context. But let's do one step at a
time. `openmany` is simple; we iterate through the nested binders, introducing one fresh variable at
a time, and substituting each bound variable for the fresh variable.

```makam
openmany : bindmany A B -> (list A -> B -> prop) -> prop.
openmany (body Body) P :- P [] Body.
openmany (bind F) P :-
  (x:A -> openmany (F x) (fun xs => P (x :: xs))).
```

STUDENT. I guess `assumemany` is similar, introducing one assumption at a time?

```makam
assumemany : (A -> B -> prop) -> list A -> list B -> prop -> prop.
assumemany P [] [] Q :- Q.
assumemany P (X :: XS) (Y :: YS) Q :- (P X Y -> assumemany P XS YS Q).
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

TODO. Use a reference below and refine wording.

ADVISOR. Yes, exactly! Just a note though -- \lamprolog typically does not allow the definition of `assumemany`, where a non-concrete predicate like `P X Y` is used as an assumption, because of logical reasons. Makam is more lax, and so is ELPI, another recent \lamprolog implementation, and allows this form statically, though there are instantiations of `P` that will fail at run-time.

STUDENT. Can I try this out?

```makam
typeof (lammany (bind (fun x => bind (fun y => body (tuple [y, x]))))) T ?
>> Yes:
>> T := arrowmany [T1, T2] (product [T2, T1]).
```

TODO. (Still WIP below!!)

STUDENT. Great, I think I got the hang of this. We could definitely add a
multiple-argument application construct `appmany` or define the rules for `eval` for
these. But that would be easy; we can do it later. Something that worries me, though --
all these fancy higher-order abstract binders, how do we ... make them concrete? Say, how
do we print them?

ADVISOR. That's actually quite easy. We just add a concrete name to them. A plain old
`string`. Our typing rules etc. do not care about it, but we could use it for parsing
concrete syntax into our abstract binding syntax, or for pretty-printing.... Let's not get
into that for the time being, but let's just say that we could have defined `bind`
with an extra `string` argument; and then `openmany` could just ignore it.

```makam-noeval
bind : string -> (Var -> bindmany Var Body) -> bindmany Var Body.
```

STUDENT. Interesting. I would like to see more about this, but maybe some other time. I
thought of another thing that could be challenging: mutually recursive `let rec`s?

ADVISOR. Sure -- how about this?

```makam
letrec : bindmany term (list term * term) -> term.
```

STUDENT. Bind many terms into a list of terms and a term. I guess `*` is for tuples... Is
the first element the definitions and the second element the body?

ADVISOR. Yes -- so, for this expression ...

```
let rec f = f_def and g = g_def in body
```

STUDENT. ... we would write something like this:

```
letrec (bind f g => body ([f_def, g_def], body))
```

ADVISOR. Yes, and we need to be careful so that the number of binders matches the number
of definitions in the list. We can go ahead and encode that in our typing rules....

STUDENT. Wait. I let you get away before with the zero binders in `bindmany`, but this is
pushing it a little bit. It doesn't sound like an accurate encoding.

ADVISOR. You're right, but we would need some sort of dependency to enforce those kinds of
limitations... and λProlog does not have dependent types.
