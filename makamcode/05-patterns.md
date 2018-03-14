# Where our hero Hagop adds pattern matching on his own

<!--
```makam
%use "04-gadts.md".
tests: testsuite. %testsuite tests.
```
-->

\begin{scenecomment}
(Our hero Roza had a meeting with another student, so Hagop is back at his
office, trying to work out on his own how to encode patterns. He is fairly
confident at this point that having explicit support for single-variable
binding is enough to model most complicated forms of binding, especially when making use of
polymorphism and GADTs.)
\end{scenecomment}

\identNormal
STUDENT. OK, so let's implement simple patterns and pattern-matching like in ML... First let's determine
the right binding structure. For a branch like:

```
| cons(hd, tl) -> ... hd .. tl ...
```

the pattern introduces 2 variables, `hd` and `tl`, which the body of the branch can refer to. But we can't really refer to those variables in the pattern itself, at least for simple patterns\footnote{There are cases where that's not the case, like in or-patterns in some ML dialects, or in dependent pattern matching, where consequent uses of the same variable perform an exact match rather than unification. We choose to omit the handling of cases like those in the present work for presentation purposes.}.... So there's no binding going on really within the pattern; instead, once we figure out how many variables a pattern introduces, we can do the actual binding all at once, when we get to the body of the branch:

```
branch(pattern, bind [# of variables in pattern].body)
```

So we could write the above branch in Makam like this:

```
branch(
  patt_cons patt_var patt_var,
  bind (fun hd => bind (fun tl => body (.. hd .. tl ..))))
```

We do have to keep the order of variables consistent somehow, so `hd`
here should refer to the first occurrence of `patt_var`, and `tl` to
the second. Based on these, I am thinking that the type of `branch`
should be something like:

```
branch : (Pattern: patt N) (Vars_Body: vbindmany term N term) -> ...
```

Wait, before I get into the weeds let me just set up some things. First, let's add a simple base
type, say `nat`s, to have something to work with as an example. I'll prefix their names with `o` for
"object language," so as to avoid ambiguity. And I will also add a `case_or_else` construct,
standing for a single-branch pattern-match construct. It should be easy to extend to a
multiple-branch construct, but I want to keep things as simple as possible. I'll inline what I had written for `branch` above into the definition of `case_or_else`.

```makam
onat : typ. ozero : term. osucc : term -> term.
typeof ozero onat. typeof (osucc N) onat :- typeof N onat.
eval ozero ozero. eval (osucc E) (osucc V) :- eval E V.
```

```
case_or_else :
  (Scrutinee: term)
  (Patt: patt N) (Vars_Body: vbindmany term N term)
  (Else: term) -> term.
```

Now for the typing rule -- it will be something like this:

```
typeof (case_or_else Scrutinee Pattern Vars_Body Else) BodyT :-
  typeof Scrutinee T,
  typeof_patt Pattern T VarTypes,
  vopenmany Vars_Body (pfun vars body =>
    vassumemany typeof vars VarTypes (typeof body BodyT)),
  typeof Else BodyT.
```

Right, so when checking a pattern, we'll have to determine both what type of scrutinee it matches,
as well as the types of the variables that it contains. We will also need `vassumemany` that is just
like `assumemany` from before but which takes `vector` arguments instead of `list`.

```
typeof_patt : [N] patt N -> typ -> vector typ N -> prop.
vassumemany : [N] (A -> B -> prop) -> vector A N -> vector B N -> prop -> prop.
(...)
```

Now, I can just go ahead and define the patterns, together with their
typing relation, `typeof_patt`.

Let me just work one by one for each pattern.

```
patt_var : patt (succ zero).
typeof_patt patt_var T (vcons T vnil).
```

OK, that's how we'll write pattern variables, introducing a single variable of a specific `typ` into the body of the branch. And the following should be good for the `onat`s I defined earlier.

```
patt_ozero : patt zero.
typeof_patt patt_ozero onat vnil.

patt_osucc : patt N -> patt N.
typeof_patt (patt_osucc P) onat VarTypes :- typeof_patt P onat VarTypes.
```

A wildcard pattern will match any value and should not introduce a variable into the body of the branch.

```
patt_wild : patt zero.
typeof_patt patt_wild T vnil.
```

OK, and let's do patterns for our n-tuples.... I guess I'll need a
type for lists of patterns too.

```
patt_tuple : pattlist N -> patt N.
typeof_patt (patt_tuple PS) (product TS) VarTypes :-
  typeof_pattlist PS TS VarTypes.
pattlist : (N: type) -> type.
pnil : patt zero.
pcons : patt N -> pattlist N' -> pattlist (N + N').
```

Uh-oh...  don't think I can do that `N + N'` really. In this `pcons` case, my pattern basically
looks like `(P, ...PS)`; and I want the overall pattern to have as many variables as `P` and `PS`
combined. But the GADTs support in \lamprolog seems to be quite basic. I do not think there's any
notion of type-level functions like plus....

However... maybe I can work around that, if I change `patt` to include an "accumulator" argument, say `NBefore`. Each constructor for patterns will now define how many pattern variables it adds to that accumulator, yielding `NAfter`, rather than defining how many pattern variables it includes... like this:

```makam
patt, pattlist : (NBefore: type) (NAfter: type) -> type.
patt_var : patt N (succ N).
patt_ozero : patt N N.
patt_osucc : patt N N' -> patt N N'.
patt_wild : patt N N.
patt_tuple : pattlist N N' -> patt N N'.

pnil : pattlist N N.
pcons : patt N N' -> pattlist N' N'' -> pattlist N N''.
```

Yes, I think that should work. I have a little editing to do in my existing predicates to use this
representation instead. For top-level patterns, we should always start with the accumulator being `zero`...

<!--
```makam
vsnoc : [N] vector A N -> A -> vector A (succ N) -> prop.
vsnoc vnil Y (vcons Y vnil).
vsnoc (vcons X XS) Y (vcons X XS_Y) :- vsnoc XS Y XS_Y.
```
-->

```makam
case_or_else :
  (Scrutinee: term)
  (Patt: patt zero N) (Vars_Body: vbindmany term N term)
  (Else: term) -> term.
```

I think I'll also have to change `typeof_patt`, so that it includes an accumulator argument of its
own:

```makam
typeof_patt : [NBefore NAfter]
  patt NBefore NAfter -> typ ->
  vector typ NBefore -> vector typ NAfter -> prop.

typeof (case_or_else Scrutinee Pattern Vars_Body Else) BodyT :-
  typeof Scrutinee T,
  typeof_patt Pattern T vnil VarTypes,
  vopenmany Vars_Body (pfun vars body =>
    vassumemany typeof vars VarTypes (typeof body BodyT)),
  typeof Else BodyT.
```

All right, let's proceed to the typing rules for patterns themselves:

```makam
typeof_patt patt_var T VarTypes VarTypes' :-
  vsnoc VarTypes T VarTypes'.
```

OK, here I need `vsnoc` to add an element to the end of a vector.
That should yield the correct order for the types of pattern variables;
I am visiting the pattern left-to-right after all.

```makam
vsnoc : [N] vector A N -> A -> vector A (succ N) -> prop.
vsnoc vnil Y (vcons Y vnil).
vsnoc (vcons X XS) Y (vcons X XS_Y) :- vsnoc XS Y XS_Y.
```

The rest should be easy to adapt....

\begin{scenecomment}
(Our hero finishes adapting the rest of the rules for \texttt{typeof\_patt},
which are available in the unabridged version of this story. After
trying a few queries, he is convinced that his implementation of
pattern matching works well. The next day, he shows his work to Roza.)
\end{scenecomment}

<!--
```makam
typeof_patt patt_ozero onat VarTypes VarTypes.

typeof_patt (patt_osucc P) onat VarTypes VarTypes' :-
  typeof_patt P onat VarTypes VarTypes'.

typeof_patt patt_wild T VarTypes VarTypes.

typeof_pattlist : [NBefore NAfter]
  pattlist NBefore NAfter -> list typ ->
  vector typ NBefore -> vector typ NAfter -> prop.

typeof_pattlist pnil [] VarTypes VarTypes.
typeof_pattlist (pcons P PS) (T :: TS) VarTypes VarTypes' :-
  typeof_patt P T VarTypes VarTypes',
  typeof_pattlist PS TS VarTypes' VarTypes''.

typeof_patt (patt_tuple PS) (product TS) VarTypes VarTypes' :-
  typeof_pattlist PS TS VarTypes VarTypes'.

(eq _PRED (lam _ (fun n => case_or_else n
  (patt_osucc patt_var) (vbind (fun pred => vbody pred))
  ozero)),
 typeof _PRED T) ?
>> Yes:
>> T := arrow onat onat.
```
-->

\identDialog

ADVISOR. That's great! I understand that this was a little tricky, but still, it was not too bad, right? Actually, I know
of one thing that is quite simple to do: the evaluation rule. On paper we typically write something roughly like:

\vspace{-1.5em}
\begin{mathpar}
\inferrule{e_1 \Downarrow v_1 \\ \texttt{match}(p, v_1) \leadsto \sigma \\ e_2[\sigma/xs] \Downarrow v_2}
          {\texttt{case\_or\_else}(e_1, p \mapsto xs.e_2, e_3) \Downarrow v_2}

\inferrule{e_1 \Downarrow v_1 \\ \texttt{match}(p, v_1) \not\leadsto \\ e_3 \Downarrow v_3}
          {\texttt{case\_or\_else}(e_1, p \mapsto xs.e_2, e_3) \Downarrow v_3}
\end{mathpar}

So `match` tries to unify a pattern with a term and yields a substitution $\sigma$ for the pattern variables if successful, which is then applied to the body of the branch. If there is no `match` to be found, then we use the `else` branch.

STUDENT. Hmm... so do we need two predicates, one for the case where the `match` is successful and one to check that a pattern *does not* match a scrutinee?

ADVISOR. Actually we could have a single `match` predicate. And we can use the logical `if-then-else` construct for the two cases, which we have not seen so far. Let me write down the evaluation rule, and I'll explain:

```makam
match : [NBefore NAfter]
  (Pattern: patt NBefore NAfter) (Scrutinee: term)
  (SubstBefore: vector term NBefore) (SubstAfter: vector term NAfter) ->
  prop.
eval (case_or_else Scrutinee Pattern Body Else) V' :-
  eval Scrutinee V,
  if (match Pattern V vnil Subst)
  then (vapplymany Body Subst Body', eval Body' V')
  else (eval Else V').
```

The `if-then-else` construct behaves as follows: when there is at least one way to prove the
condition, it proceeds to the `then` branch, otherwise it goes to the `else` branch. Pretty standard,
really. It is one thing that the Prolog cut statement, `!`, is useful for, but I find that using cut
makes for less readable code. \citet{kiselyov05backtracking} is worth reading for alternatives to
the cut statement and the semantics of `if`-`then`-`else` and `not` in logic programming, and Makam
follows that paper closely.

STUDENT. I see. Now, I noticed a `vapplymany` predicate -- what is that?

ADVISOR. That is a standard-library predicate. It is used to perform simultaneous substitution for all the variables in our multiple binding type, `vbindmany`. Or another way to say it, it's the equivalent of HOAS function application for `vbindmany`:

```makam
vapplymany : [N] vbindmany Var N Body -> vector Var N -> Body -> prop.
vapplymany (vbody Body) vnil Body.
vapplymany (vbind F) (vcons E ES) Body :- vapplymany (F E) ES Body.
```

STUDENT. I see... OK, I think I know how to continue. I will write a few of the `match` rules down.

```makam
match patt_var X Subst Subst' :- vsnoc Subst X Subst'.
match patt_wild X Subst Subst.
match patt_ozero ozero Subst Subst.
match (patt_osucc P) (osucc V) Subst Subst' :-
  match P V Subst Subst'.
```

\begin{scenecomment}
(Our heroes also write down the rules for multiple patterns and tuples, which are
available in the unabridged version of this story.)
\end{scenecomment}

<!--
```makam
matchlist : [NBefore NAfter]
  (Pattern: pattlist NBefore NAfter) (Scrutinee: list term)
  (SubstBefore: vector term NBefore) (SubstAfter: vector term NAfter) ->
  prop.
match (patt_tuple PS) (tuple VS) Subst Subst' :-
  matchlist PS VS Subst Subst'.

matchlist pnil [] Subst Subst.
matchlist (pcons P PS) (V :: VS) Subst Subst'' :-
  match P V Subst Subst', matchlist PS VS Subst' Subst''.

(eq _PRED (lam _ (fun n => case_or_else n
  (patt_osucc patt_var) (vbind (fun pred => vbody pred))
  ozero)),
 typeof _PRED T,
 eval (app _PRED ozero) PRED0, eval (app _PRED (osucc (osucc ozero))) PRED2) ?
>> Yes:
>> T := arrow onat onat, PRED0 := ozero, PRED2 := osucc ozero.
```
-->

STUDENT. Let's try this out with a simple example -- how about predecessor for natural
numbers?

```makam
eval (case_or_else (osucc (osucc ozero))
     (patt_osucc patt_var) (vbind (fun pred => vbody pred))
     ozero)
  V ?
>> Yes:
>> V := osucc ozero.
```

ADVISOR. Looks good! You seem to be getting the hang of this. How about we do something
challenging then? Say, type synonyms?

NEEDFEEDBACK. \todo{I have switched to a more incremental presentation here, adding more explanation, since it seems that we lost a few reviewers here last time. However, this makes this section too long; it looks like the centerpiece of the paper, but it shouldn't be. (For example, there's a blog post with a similar encoding from a few years back.) Between this and algebraic datatypes, we will definitely need to cut something in order to have more in-depth explanations, but I'm not sure what. Thoughts? Maybe we should drop the evaluation rule, since it's not introducing anything new other than `if`-`then`-`else` and `appmany`?}
