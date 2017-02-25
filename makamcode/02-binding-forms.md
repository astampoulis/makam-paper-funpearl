# Where our heroes add parentheses and discover how to do multiple binding

<!--
```makam
%use "01-base-language".
```
-->

STUDENT. Still, I feel like we've been playing to the strengths of \lamprolog... Yes,
single-variable binding, substitutions and so on work nicely, but how about any other form
of binding? Say, binding multiple variables at the same time? We are definitely going to
need that for the language we have in mind, and I remember that \citet{keuchel2016needle}
mention that HOAS encodings do not work for such forms of binding.

ADVISOR. I beg to differ. Let's try it out, let's try adding multiple-argument functions
for example -- I mean uncurried ones. Want to give it at try?

STUDENT. Let me see. Well, I want to write something like this, but I know this is wrong.

```
lammany : (list term -> term) -> term.
```

ADVISOR. Yes, that doesn't quite work. This would introduce a fresh variable for `list`s,
not a number of fresh variables for `term`s. HOAS functions are parametric too, which
means we cannot even get to the potential elements of the fresh `list`.

STUDENT. Right. So I don't know, instead we want to use a type that stands for `term ->
term`, `term -> term -> term`, and so on. Can we write `term -> ... -> term`?

ADVISOR. Well, not quite, but we have already defined something similar, a type that
roughly stands for `term * term`, `term * term * term`, we did not need anything special
for that...

STUDENT. You mean the `list` type?

ADVISOR. Exactly. What do you think about this definition?

```makam
bindmanyterms : type.
bindnil : term -> bindmanyterms.
bindcons : (term -> bindmanyterms) -> bindmanyterms.
```

STUDENT. Hmm. That looks quite similar to lists, the parentheses in `cons` are
different. `nil` gets an extra `term` argument too...

ADVISOR. Yes... So what is happening here is that `bindcons` takes a single argument,
adding another binder; and `bindnil` is when we get to the body and don't need any more
binders, so we just need the body.

STUDENT. Oh so could we generalize their types? Maybe that will help me get a better
grasp of it. How is this?

```makam
bindmany : type -> type -> type.
bindbase : Body -> bindmany Variable Body.
bindnext : (Variable -> bindmany Variable Body) -> bindmany Variable Body.
```

ADVISOR. This looks great! Though let me say, I cheated a bit: in order for the
constructors to look nicer, we have allowed binding zero variables. We could definitely
disallow that by changing `bindbase` to take a `Variable -> Body` argument instead, but
let's just go along with this, it will make all our predicates simpler to write too.

STUDENT. I see. That is quite an interesting datatype, is there some reference about it?

ADVISOR. Not that I know of -- though I think this is part of PL folklore. After I started
using this in Makam, I noticed similar constructions in the wild, for example in MTac
\citep{ziliani2013mtac}, for the parametric HOAS implementation of telescopes.

STUDENT. Interesting. So how do we work with `bindmany`? I know we can now define
`lammany` as follows, but how about the typing rules?

```makam
lammany : bindmany term term -> term.
```

ADVISOR. Well, for the built-in single binding type, we used three built-in
operations:

- variable substitution, encoded through HOAS function application
- introducing a fresh variable, through the predicate form `x:term -> ...`
- introducing a new assumption, through the predicate form `P -> ...`

STUDENT. So we should add three operations for `bindmany` that correspond to those, right?

ADVISOR. Correct, and they will be predicates, since that's the only kind of computation
we can define in \lamprolog{}. So let's first do the predicate that generalizes
application:

```makam
applymany : bindmany A B -> list A -> B -> prop.
applymany (bindbase Body) [] Body.
applymany (bindnext F) (HD :: TL) Body :-
  applymany (F HD) TL Body.
```

STUDENT. I see, so given a `bindmany` and a substitution for the variables, perform
simultaneous substitution to get the body. 

ADVISOR. Right. And a predicate for introducing multiple variables at once. Then you try
doing multiple assumptions.

```makam
intromany : bindmany A B -> (list A -> prop) -> prop.
intromany (bindbase _) P :- P [].
intromany (bindnext F) P :-
  (x:A -> intromany (F x) (fun tl => P (x :: tl))).
```

STUDENT. Let me see. So pattern match on the two cases, introduce an extra assumption in
the `bindnext` case. How does this look?

```makam
assumemany : (A -> B -> prop) -> list A -> list B -> prop -> prop.
assumemany P [] [] Q :- Q.
assumemany P (X :: XS) (Y :: YS) Q :- (P X Y -> assumemany P XS YS Q).
```

ADVISOR. That looks good. Maybe one thing to note is that this last rule might not work in
other \lamprolog implementations, as it introduces an assumption for a predicate that is
not known statically, and that is usually not allowed. That's why I said we should use
Makam.

STUDENT. Is that a limitation that has to do with the correspondence of \lamprolog to
logic? 

ADVISOR. Not really, I believe that is because of implementation concerns mostly -- it
would significantly complicate VMs for the language. But Makam is interpreted, so it
sidesteps that.

STUDENT. Interesting. So let me try doing the typing rule now. I'll add a type for
multiple argument functions. Would this work?

<!-- add just this line to makam:
```makam
arrowmany : list typ -> typ -> typ.
```
--->

```
arrowmany : list typ -> typ -> typ.
typeof (lammany F) (arrowmany TS T') :-
  intromany F (fun xs =>
    applymany F xs Body,
    assumemany typeof xs TS (typeof Body T')).
```

ADVISOR. Almost. There is an issue here: the unification variable `Body` cannot capture
the free variables `xs` that get introduced later. Unification variables are allowed to
capture all the free variables in scope at the point where they are introduced. By
default, they get introduced when the rule fires, but here we need to explicitly say that
`Body` should be introduced when `intromany` uses its predicate argument; Makam uses
square bracket notation for that. Oh, and a Makam idiosyncrasy: the parser isn't clever
enough to tell that the predicate argument to `intromany` is, in fact, a predicate, so we
can't use the normal predicate syntax for it. There is the syntactic form `pfun` for
anonymous predicates, save for predicate syntax, it's entirely identical to `fun`. So:

```makam
typeof (lammany F) (arrowmany TS T') :-
  intromany F (pfun xs => (
    [Body]
      applymany F xs Body,
      assumemany typeof xs TS (typeof Body T'))).
```

STUDENT. Would it make sense to combine `intromany` and `appmany` into one predicate, like
this, since we will probably always need both the variables and the body of a `bindmany`?

```makam
openmany : bindmany A B -> (list A -> B -> prop) -> prop.
openmany F P :-
  intromany F (pfun xs => [Body] applymany F xs Body, P xs Body).
```

ADVISOR. Yes, that predicate turns out to be quite useful. Let's try out a query now!

```makam
typeof (lammany (bindnext (fun x => bindnext (fun y => bindbase (tuple [y, x]))))) T ?
>> Yes:
>> T := arrowmany [T1, T2] (product [T2, T1])
```

STUDENT. Great, I think I got the hang of this. We could definitely add a
multiple-argument application construct `appmany` or define the rules for `eval` for
these. But that would be easy, we can do that later. Something that worries me though --
all these fancy higher-order abstract binders, how do we ... make them concrete? Say, how
do we print them?

ADVISOR. That's actually quite easy. We just add a concrete name to them. A plain old
`string`. Our typing rules etc. do not care about it, but we could use it for parsing
concrete syntax into our abstract binding syntax, or for pretty-printing... Let's not get
into that for the time being, but let's just say that we could have defined `bindnext`
with an extra `string` argument; and then `intromany` and friends would just ignore it.

```
bindnext : string -> (Variable -> bindmany Variable Body) -> bindmany Variable Body.
```

STUDENT. Interesting, I would like to see more about this, but maybe some other time. I
thought of another thing that could be challenging: mutually recursive `let rec`s?

ADVISOR. Sure -- how about this?

```makam
letrec : bindmany term (list term) -> bindmany term term -> term.
```

STUDENT. Bind many terms into a list of terms, then bind other terms into a term... Is the
first list the definitions and the second list the body?

ADVISOR. Yes -- just to make this clear, for this expression ...

```
let rec f = f_def and g = g_def in body
```

STUDENT. ... we would write something like this:

```
letrec (bindnext (fun f => bindnext (fun g => bindbase ([f_def, g_def]))))
       (bindnext (fun f => bindnext (fun g => bindbase body)))
```

ADVISOR. Yes, and we need to be careful so that the number of binders matches between the
definitions and the body, and also that we have as many definitions as we have
binders. We can go ahead and encode that in our typing rules...

STUDENT. Wait. I let you get away before with the zero binders in `bindmany`, this is
pushing it a little bit. This doesn't sound like an accurate encoding.

ADVISOR. You're right, but we would need some sort of dependency to enforce those kinds of
limitations... and \lamprolog does not have dependent types.

STUDENT. Well neither did Haskell a few years back, people still got functional pearls
published though?

ADVISOR. That is a weird thing to mention.
