# Where our heroes break into song and add more ML features

<!--
```makam
%use "05-patterns.md".
tests: testsuite. %testsuite tests.
```
-->

\begin{scenecomment}
(Our heroes need a small break, so they work on a couple of features while improvising on a makam\footnote{Makam is the system of melodic modes used in traditional Arabic and Turkish music and in the Greek rembetiko, comprised of a set of scales, patterns of melodic development, and rules for improvisation.}. Roza is singing, and Hagop is playing the oud.)
\end{scenecomment}

\begin{verse}
``Explicit System F polymorphism is easy, at some point we'll do Hindley-Milner too. \\
Types are well-formed by construction, an extra `$\vdash \tau \; \text{wf}$' judgment we won't do.''
\end{verse}

```makam
forall : (typ -> typ) -> typ.
lamt : (typ -> term) -> term.
appt : term -> typ -> term.
typeof (lamt E) (forall T) :- (a:typ -> typeof (E a) (T a)).
typeof (appt E T) (TF T) :- typeof E (forall TF).
```

\begin{verse}
``We are now adding top-level programs, to get into datatype declarations. \\
We would rather do modules, but those would need quite a bit of deliberation. \\
And we still have contextual types to do, those will require our full attention.''
\end{verse}

```makam
program : type.
wfprogram : program -> prop.

let : term -> (term -> program) -> program.
wfprogram (let E P) :- typeof E T, (x:term -> typeof x T -> wfprogram (P x)).

main : term -> program.
wfprogram (main E) :- typeof E _.
```

<!--
First we add polymorphism, therefore extending our simply typed lambda calculus to System
F. We will only consider the explicit polymorphism case for the time being, leaving type
inference for later.

We need a type for quantification over types, as well as term-level constructs for
functions over types and instantiating a polymorphic function with a specific type.
The typing rules are straightforward.

One thing to note is that in a pen-and-paper version, we would need to define a new context that
keeps track of type variables that are in scope (typically named $\Delta$), and an auxiliary
judgment of the form $\Delta \vdash \tau \; \text{wf}$ that checks that all type variables used
in $\tau$ are in scope. Here we get type well-formedness for free. Furthermore, if we had to
keep track of further information about type variables (e.g. their kinds), we could have added
an assumption of the form `kindof a K ->`. Since the local assumption context can carry rules
for any predicate, no extra declaration or change to the existing rules would be needed, as
would be required in the pen-and-paper version in order to incorporate the new $\Delta$
context.

With these additions, we can give a polymorphic type to the identity function:

```makam
typeof (lamt (fun a => lam a (fun x => x))) T ?
```

Moving on towards a more ML-like language, we would like to add the option to declare algebraic
datatypes. We must first introduce a notion of top-level programs, each composed of a
series of declarations of types and terms, as well as a predicate to check that a program is
well-formed:

```
program : type.
wfprogram : program -> prop.
```

Let us add `let` definitions as a first example of a program component, each introducing a term
variable that can be used in the rest of the program:

```
let : term -> (term -> program) -> program.

wfprogram (let E P) :-
  typeof E T,
  (x:term -> typeof x T -> wfprogram (P x)).
```

We also need a "last" component for the program, typically a main expression:

```
main : term -> program.

wfprogram (main E) :-
  typeof E _.
```
-->

---

ADVISOR. I think we are ready to do polymorphic algebraic datatypes now. We'll add a type
for type constructors, like `list`, dependent on their arity; and a type for the
constructors of a datatype. Also a type for constructor declarations, dependent on the
number of constructors they introduce:

```makam
typeconstructor : type -> type.
constructor : type.

ctor_declaration : type -> type.
nil : ctor_declaration unit.
cons : list typ -> ctor_declaration T -> ctor_declaration (constructor * T).
```

STUDENT. Oh, so each constructor takes multiple arguments. Great. So datatype declarations would be something like this:

```makam
datatype_declaration : type -> type -> type.
datatype_declaration : 
  (typeconstructor Arity -> dbind typ Arity (ctor_declaration Ctors)) ->
  datatype_declaration Arity Ctors.
datatype :
  datatype_declaration Arity Ctors ->
  (typeconstructor Arity -> dbind constructor Ctors program) -> program.
```

ADVISOR. Right, so when declaring a datatype, we introduce a `typeconstructor` variable so
that we can refer to the type recursively when we declare our constructors. And we also have
access to the right number of polymorphic variables, matching the `Arity` of the
constructor. I like how you split out the declaration of the type itself from the "rest of the program" part, since this could become unwieldy otherwise.

STUDENT. That's what I thought too. And I see why you made the type constructors carry their arities -- to keep types well-formed by construction. In order to be able to actually refer to the type constructors, though, don't we need a type former:
```makam
tconstr : typeconstructor T -> subst typ T -> typ.
```

ADVISOR. We do. Also keep in mind that in a richer type system, we probably would need an
extra kind-checking predicate. But this will do for now. Let's just make sure this is fine --
I'll write down the declaration of binary trees, to make sure we're not missing anything, and typecheck it with Makam.

```makam-noeval
%type (datatype_declaration
  (fun tree => dbindnext (fun a => dbindbase
    [ (* leaf *) [],
      (* node *) [tconstr tree [a], a, tconstr tree [a]] ]))).
>> (...) : datatype_declaration (typ * unit) (constructor * constructor * unit)
```

STUDENT. Looks good. Should we proceed to the actual well-formedness for datatype
declarations? I think we will need a predicate to keep track of information about a
constructor -- which datatype it belongs to and what arguments it expects. That way we
can carry that information in the assumptions context.

```makam
constructor_info :
  typeconstructor Arity -> constructor -> dbind typ Arity (list typ) -> prop.
```

<!--
The order of this is wrong in the narrative, but we need the declaration here for Makam.

```makam
constructor_polytypes : [Arity Ctors PolyTypes]
  ctor_declaration Ctors -> subst typ Arity ->
  subst (dbind typ Arity (list typ)) PolyTypes -> prop.

constructor_polytypes [] _ [].
constructor_polytypes (CtorType :: CtorTypes) TypVars (PolyType :: PolyTypes) :-
  applymany PolyType TypVars CtorType,
  constructor_polytypes CtorTypes TypVars PolyTypes.
```
-->

ADVISOR. Yes, and we are mostly ready otherwise:

```makam
wfprogram (datatype (datatype_declaration ConstructorDecls) Program') :-
  (dt:(typeconstructor T) -> ([PolyTypes]
    openmany (ConstructorDecls dt) (pfun tvars constructor_decls => (
      constructor_polytypes constructor_decls tvars PolyTypes)),
    openmany (Program' dt) (pfun constructors program' =>
      assumemany (constructor_info dt) constructors PolyTypes
      (wfprogram program')))).
```

STUDENT. This is a tricky piece of code. Let me stare at it for a while. (...) What is this new `constructor_polytypes` predicate?

ADVISOR. I'm using that in order to re-abstract over the type variables.... See, in the
constructor declaration, we've introduced a number of type variables. We need to abstract
over them, in order to get the polymorphic type of each constructor for the rest of the
program. Note that `PolyTypes` can't capture the type variables `tvars` we
introduce.

STUDENT. I think I got it. Let me try to implement it.

ADVISOR. Here's a hint.
```makam
(x:typ -> y:typ -> applymany PolyType [x, y] (arrow y x)) ?
>> Yes:
>> PolyType := dbindnext (fun x => dbindnext (fun y => dbindbase (arrow y x))).
```

\begin{scenecomment}
(After a few attempts, Hagop comes up with the following definition.)
\end{scenecomment}

```
constructor_polytypes : [Arity Ctors PolyTypes]
  ctor_declaration Ctors -> subst typ Arity ->
  subst (dbind typ Arity (list typ)) PolyTypes -> prop.

constructor_polytypes [] _ [].
constructor_polytypes (CtorType :: CtorTypes) TypVars (PolyType :: PolyTypes) :-
  applymany PolyType TypVars CtorType,
  constructor_polytypes CtorTypes TypVars PolyTypes.
```

STUDENT. I see what you were getting at. I think this is an interesting use of
`applymany`: we are using it in the opposite direction than what we have used it so far.
We are giving it `TypVars` and `CtorType` as inputs, and then we get `PolyType`, with all
the needed binders, as an output. And since the way we're using it, `PolyType` cannot
capture the `TypVars`, it all works out correctly!

ADVISOR. Excellent! Let's add the term-level former for constructors, too.

STUDENT. That is easy, compared to what we just did.

```makam
constr : constructor -> list term -> term.
typeof (constr Constructor Args) (tconstr TypConstr TypArgs) :-
  constructor_info TypConstr Constructor PolyType,
  applymany PolyType TypArgs Typs, map typeof Args Typs.
```

ADVISOR. You're getting the hang of this. Let's do something actually difficult, then; type synonyms.

<!--
Additional information.

Patterns and their typing rule:

```makam
patt_constr : constructor -> pattlist T T' -> patt T T'.

typeof (patt_constr Constructor Args) S' S (tconstr TypConstr TypArgs) :-
  constructor_info TypConstr Constructor PolyType,
  applymany PolyType TypArgs Typs,
  typeof Args S' S Typs.
```

Example: definition of lists and append.

```makam
wfprogram
  (datatype
    (datatype_declaration (fun llist => dbindnext (fun a => dbindbase (
    [ [] (* nil *) ,
      [a, tconstr llist [a]] (* cons of a * list a *) ]))))
  (fun llist => dbindnext (fun lnil => dbindnext (fun lcons => dbindbase (
  (main
    (letrec
      (dbindnext (fun append => dbindbase (
      [ lamt (fun a => lam (tconstr llist [a]) (fun l1 => lam _ (fun l2 =>
        case_or_else l1
          (patt_constr lcons [patt_var, patt_var])
            (dbindnext (fun hd => dbindnext (fun tl => dbindbase (
            constr lcons [hd, app (app (appt append _) tl) l2]))))
          l2))) ],
      (app (app (appt append _)
        (constr lcons [zero, constr lnil []]))
        (constr lcons [zero, constr lnil []]))
      )))))))))) ?
>> Yes.
```

The semantics:

```makam
patt_to_term (patt_constr Constructor Args) (constr Constructor Args') S' S :-
  pattlist_to_termlist Args Args' S' S.

eval (constr C Args) (constr C Args') :-
  map eval Args Args'.

eval : program -> program -> prop.

eval (let E P') P'' :-
  eval E V, eval (P' V) P''.

eval (datatype D P') (datatype D P'') :-
  (dt:(typeconstructor T) ->
    intromany CS (pfun cs => ([P'c P''c]
    applymany (P' dt) cs P'c,
    applymany (P'' dt) cs P''c,
    eval P'c P''c))).

eval (main E) (main V) :-
  eval E V.
```

Example of evaluation:

```makam
(eq _PROGRAM (

    (datatype
      (datatype_declaration (fun llist => dbindnext (fun a => dbindbase (
      [ [] (* nil *) ,
        [a, tconstr llist [a]] (* cons of a * list a *) ]))))
      (fun llist => dbindnext (fun lnil => dbindnext (fun lcons => dbindbase (

    (main (constr lcons [zero, constr lnil []]))

    )))))),

 wfprogram _PROGRAM,
 eval _PROGRAM FINAL) ?
>> Yes:
>> FINAL := datatype (datatype_declaration (fun llist => dbindnext (fun a => dbindbase (cons nil (cons (cons a (cons (tconstr llist (cons a nil)) nil)) nil))))) (fun llist => dbindnext (fun lnil => dbindnext (fun lcons => dbindbase (main (constr lcons (cons zero (cons (constr lnil nil) nil))))))).

```
-->
