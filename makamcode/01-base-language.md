# Where our heroes get the easy stuff out of the way

STUDENT. OK, let's just start with the simply typed lambda calculus to see how this
works. Let's define just the basics, application, lambda abstraction and the arrow type.

ADVISOR. Right. We will first need to define the two meta-types for these two sorts:

```makam
term : type.
typ : type.
```

STUDENT. Oh, so `type` is the reserved keyword for the meta-level kind of types, and we'll
use `typ` for our object-level types?

ADVISOR. Exactly. And let's do the easy constructors first:

```makam
app : term -> term -> term.
arrow : typ -> typ -> typ.
```

STUDENT. So we add constructors to a type at any point, we do not list them out when we
define it like in Haskell. But how about lambdas? I have heard that \lamprolog supports
higher-order abstract syntax, which should make those really easy to add too, right?

ADVISOR. Yes, functions at the meta-level are parametric, so they correspond exactly to
single variable binding -- they cannot perform any computation, and thus we do not have to
worry about exotic terms. So this works fine for Church-style lambdas:

```makam
lam : typ -> (term -> term) -> term.
```

STUDENT. I see. And how about the typing judgement, $\Gamma \vdash e : \tau$ ?

ADVISOR. Let's add a predicate for that. Only, no $\Gamma$, there is an implicit context
of assumptions:

```makam
typeof : term -> typ -> prop.
```

STUDENT. Let me see if I can get the typing rule for application. I know that in Prolog we
write the conclusion of a rule first, and the premises follow the `:-` sign. Does
something like this work?

```makam
typeof (app E1 E2) T' :-
  typeof E1 (arrow T T'), typeof E2 T.
```

ADVISOR. Yes! That's exactly right. Makam uses capital letters for unification variables.

STUDENT. I will need help with the lambda typing rule though. What's the equivalent of
extending the context as in $\Gamma, x : \tau$ ?

ADVISOR. Simple, we introduce a fresh constructor for terms, and a new typing rule for it:

```makam
typeof (lam T1 E) (arrow T1 T2) :-
  (x:term -> typeof x T1 -> typeof (E x) T2).
```

STUDENT. Hmm, so `x:term ->` introduces the fresh constructor standing for the new
variable, and `typeof x T1 ->` introduces the new assumption? Oh, and we need to get to
the body of the lambda function in order to type-check it, that's why you do `E x`.

ADVISOR. Yes. Note that the introductions are locally scoped, so they are only into effect
for the recursive call to `typeof`.

STUDENT. Makes sense. So do we have a type checker already? Can we run queries?

ADVISOR. We do! Observe:

```makam
typeof (lam _ (fun x => x)) T ?
>> Yes:
>> T := arrow T1 T1
```

STUDENT. Cool! But wait, last time I implemented unification in my toy STLC implementation
it was easy to make it go into an infinite loop with $\lambda x. x x$. How does that work
here?

ADVISOR. Well you were missing the occurs-check. \lamprolog unification includes it:
```makam
typeof (lam _ (fun x => app x x)) T' ?
>> Impossible.
```

STUDENT. Right. Cool, so what else can we do? How about adding tuples to our language? Can
we use something like a polymorphic list?

ADVISOR. Sure! \lamprolog has polymorphic types and higher-order predicates:

```
list : type -> type.
nil : list A.
cons : A -> list A -> list A.

map : (A -> B -> prop) -> list A -> list B -> prop.
map P nil nil.
map P (cons X XS) (cons Y YS) :- P X Y, map P XS YS.
```

STUDENT. Nice! So this should work:

```makam
tuple : list term -> term.
product : list typ -> typ.
typeof (tuple ES) (product TS) :-
  map typeof ES TS.
```

ADVISOR. It does! And we can use syntactic sugar for `cons` and `nil` too:

```makam
typeof (lam _ (fun x => lam _ (fun y => tuple [x, y]))) T ?
>> Yes:
>> T := arrow T1 (arrow T2 (product [T1, T2]))
```

STUDENT. So how about evaluation? Can we write the big-step semantics too?

ADVISOR. Why not? Let's add a predicate and do the two easy rules:

```makam
eval : term -> term -> prop.
eval (lam T F) (lam T F).
eval (tuple ES) (tuple VS) :- map eval ES VS.
```

STUDENT. OK, let me try my hand at the beta-redex case. I'll just do call-by-value. And I
think in $\lamprolog$ function application is exactly capture-avoiding substitution, so
this should be fine:

```makam
eval (app E E') V'' :-
  eval E (lam _ F), eval E' V', eval (F V') V''.
```

ADVISOR. Exactly! See, I told you this would be easy!