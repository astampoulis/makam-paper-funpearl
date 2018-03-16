ADVISOR. That's great! I understand that this was a little tricky, but still, it was not too bad, right? Actually, I know
of one thing that is quite simple to do: the evaluation rule. On paper we typically write something roughly like:

\vspace{-1.5em}
\begin{mathpar}
\inferrule{e_1 \Downarrow v_1 \\ \texttt{match}(p, v_1) \leadsto \sigma \\ e_2[\sigma/xs] \Downarrow v_2}
          {\texttt{case\_or\_else}(e_1, p \mapsto xs.e_2, e_3) \Downarrow v_2}

\inferrule{e_1 \Downarrow v_1 \\ \texttt{match}(p, v_1) \not\leadsto \\ e_3 \Downarrow v_3}
          {\texttt{case\_or\_else}(e_1, p \mapsto xs.e_2, e_3) \Downarrow v_3}
\end{mathpar}

\noindent
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

\noindent
The `if-then-else` construct behaves as follows: when there is at least one way to prove the
condition, it proceeds to the `then` branch, otherwise it goes to the `else` branch. Pretty standard,
really. It is one thing that the Prolog cut statement, `!`, is useful for, but I find that using cut
makes for less readable code. \citet{kiselyov05backtracking} is worth reading for alternatives to
the cut statement and the semantics of `if`-`then`-`else` and `not` in logic programming, and Makam
follows that paper closely.

STUDENT. I see. Now, I noticed a `vapplymany` predicate -- what is that?

ADVISOR. That is a standard-library predicate. It is used to perform simultaneous substitution for all the variables in our multiple binding type, `vbindmany` (also available as `appmany` for `bindmany`). Or another way to say it, it's the equivalent of HOAS function application for `vbindmany`:

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

typeof (case_or_else (tuple [tuple [], ozero]) (patt_tuple (pcons patt_var (pcons patt_var pnil)))
                     (vbind (fun t => vbind (fun n => vbody (osucc n))))
                     ozero) T ?
>> Yes:
>> T := onat.
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
