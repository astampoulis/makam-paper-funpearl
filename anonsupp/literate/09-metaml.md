# In which our heroes tackle a new level of meta, contexts and substitutions

<!--
```makam
%use "07-structural.md".
tests: testsuite. %testsuite tests.
```
-->

STUDENT. I'm fairly confident by now that Makam should be able to handle the research idea
we want to try out. Shall we get to it?

ADVISOR. Yes, it is time. So, what we are aiming to do is add a facility for type-safe, heterogeneous meta-programming to our object language, similar to MetaHaskell \citep{mainland2012explicitly}. This way we can manipulate the terms of a *separate* object language in a type-safe manner.

STUDENT. Exactly. For the research language we have in mind, we aim for our object language to be a
formal logic, so our language will be similar to Beluga \citep{beluga-main-reference} or VeriML
\citep{veriml-main-reference}. We will also need dependent functions and pattern-matching over
the object language... But we don't need to do all of that; let's just do a basic version
for now, and I can do the rest on my own.

\newcommand\dep[1]{\ensuremath{#1}}
\newcommand\lift[1]{\ensuremath{\langle#1\rangle}}
\newcommand\odash[0]{\ensuremath{\vdash_{\text{o}}}}
\newcommand\wf[0]{\ensuremath{\; \text{wf}}}
\newcommand\aq[1]{\ensuremath{\texttt{aq}(#1)}}
\newcommand\aqopen[1]{\ensuremath{\texttt{aqopen}(#1)}}

ADVISOR. Sounds good. First, let's agree on some terminology, because a lot of words are getting
overloaded a lot. Let us call *objects* $o$ any sorts of terms of the object language that we will
be manipulating.  And, for lack of a better word, let us call *classes* $c$ the "types" that
characterize those objects through a typing relation of the form $\Psi \odash o : c$. It is
unfortunate that these names suggest object-orientation, but this is not the intent.

STUDENT. I see what you are saying. Let's keep the objects simple -- to start, let's just do the
terms of the simply typed lambda calculus (STLC). In that case our classes will just be the types
of STLC. The objects are run-time entities: essentially, our programs will be able to "compute"
objects. So we need a way to return (or "lift") an object $o$ as a meta-level value $\lift{o}$.

ADVISOR. We are getting into many levels of meta -- there's the metalanguage we're
using, Makam; there's the object language we are encoding, which is now becoming a metalanguage in
itself, let's call that Heterogeneous Meta ML Light (HMML?); and there's the "object-object"
language that HMML is manipulating. One option would be to have the object-object language be the
full HMML metalanguage itself, which would lead us to a homogeneous, multi-stage language like
MetaML \citep{metaml-main-reference}. But, I agree, we should keep the object-object language
simple: the STLC will suffice.

STUDENT. Great. How about we try to do the standard example of a staged `power` function?
Here's a rough sketch, where I'm using `~I` for antiquotation:

```
let power (n: onat): < stlc.arrow stlc.onat stlc.onat > =
  match n with
    0 => < stlc.lam (fun x => 1) >
  | S n' => letobj I = power n' in
      < stlc.lam (fun x => stlc.mult (stlc.app ~I x) x) >
```

ADVISOR. It's a plan. So, let's get to it. Should we write some of the system down on paper first?

STUDENT. Yes, that would be very useful. For this example, we will need the lifting construct $\lift{\cdot}$ and the
`letobj` form. Here are their typing
rules, which depend on an appropriately defined typing judgment $\Psi \odash o : c$ for objects. In
our case, this will initially match the $\Delta \vdash \hat{e} : \hat{t}$ typing judgment for STLC (I'll use hats for terms of STLC, to disambiguate them from terms of HMML). We
use $\dep{i}$ for variables standing for objects, which we will call *indices*. And we will need
a way to antiquote indices inside STLC terms, which means that we will have to *extend* the STLC terms as well as their
typing judgment accordingly. We store indices in the $\Psi$ context, so the STLC typing judgment will end up having the form $\Psi; \Delta \vdash \hat{e} : \hat{t}$. Last, I'll also write down the evaluation rules of the new constructs, as they are quite simple.

\newcommand\stlce[0]{\hat{e}}
\newcommand\stlct[0]{\hat{t}}
\newcommand\stlc[1]{\hat{#1}}
\vspace{-1.5em}
\begin{mathpar}
\begin{array}{ll}
\rulename{Ob-Ob-Syntax}                                                   & \rulename{HMML-Syntax} \\
\stlce  ::= \lambda x:\stlct.\stlce \; | \; \stlce_1 \; \stlce_2 \; | \; x \; | \; n \; | \; \stlce_1 * \stlce_2 \; | \; \textbf{\aq{i}} & e ::= \text{...} \; | \; \lift{\dep{o}} \; | \; \texttt{letobj} \; \dep{i} = \dep{e} \; \texttt{in} \; e' \\
\stlct  ::= \stlct_1 \to \stlct_2 \; | \; \stlc{\text{nat}} & \tau ::= \text{...} \; | \; \lift{\dep{c}} \\
\dep{o} ::= \stlce \hspace{1.5em} \dep{c} ::= \stlct &
\end{array}
\end{mathpar}
\begin{mathpar}
\inferrule[Typeof-LiftObj]
          {\dep{\Psi} \odash \dep{o} : \dep{c}}
          {\Gamma; \dep{\Psi} \vdash \lift{\dep{o}} : \lift{\dep{c}}}

\inferrule[Typeof-LetObj]
          {\Gamma; \dep{\Psi} \vdash e : \lift{\dep{c}} \\ \Gamma; \dep{\Psi}, \; \dep{i} : \dep{c} \vdash e' : \tau \\ i \not\in \text{fv}(\tau)}
          {\Gamma; \dep{\Psi} \vdash \texttt{letobj} \; \dep{i} = e \; \texttt{in} \; e' : \tau}

\inferrule[STLC-Typeof-Antiquote]
          {\dep{i} : \stlct \in \Psi}
          {\Psi; \Delta \vdash \aq{\dep{i}} : \stlct}
\end{mathpar}
\begin{mathpar}
\inferrule[Eval-LiftObj]
          {\hspace{1em}}{\lift{\dep{o}} \Downarrow \lift{\dep{o}}}

\inferrule[Eval-LetObj]
          {e \Downarrow \lift{\dep{o}} \\ e'[\dep{o}/\dep{i}] \Downarrow v}
          {\texttt{letobj} \; \dep{i} = e \; \texttt{in} \; e' \Downarrow v}

\begin{array}{l}
\rulename{SubstObj} \\
  e[\dep{o}/\dep{i}] = e' \; \text{is defined by} \\ \text{structural recursion, save for:} \\ \hspace{2em} {\aq{\dep{i}}[\stlce/\dep{i}] = \stlce}
\end{array}
\end{mathpar}

The typing rules should be quite simple to transcribe to Makam:

```makam
object, class, index : type.
classof : object -> class -> prop.
classof_index : index -> class -> prop.
subst_obj : (I_E: index -> term) (O: object) (E_OforI: term) -> prop.

liftobj : object -> term. liftclass : class -> typ.
typeof (liftobj O) (liftclass C) :- classof O C.

letobj : term -> (index -> term) -> term.
typeof (letobj E EF') T :-
  typeof E (liftclass C), (i:index -> classof_index i C -> typeof (EF' i) T).

eval (liftobj O) (liftobj O).
eval (letobj E I_E') V :-
  eval E (liftobj O), subst_obj I_E' O E', eval E' V.
```

ADVISOR. Great. I'll add the object language in a separate namespace prefix -- we can use `\texttt{\%extend}' for going
into a namespace -- and I'll just copy-paste our STLC code from earlier on, plus natural numbers. Let me also add our new antiquote as a new STLC term constructor!

```
%extend stlc.
term : type. typ : type. typeof : term -> typ -> prop.
...
aq : index -> term.
%end.
```

<!--
We don't have to copy-paste the code, we can import the previous file into a separate namespace. But let's add natural numbers too.

```makam
%extend stlc.
term : type. typ : type.
typeof : term -> typ -> prop.

app : term -> term -> term.
lam : typ -> (term -> term) -> term.
arrow : typ -> typ -> typ.

typeof (app E1 E2) T' :- typeof E1 (arrow T T'), typeof E2 T.
typeof (lam T1 E) (arrow T1 T2) :- (x:term -> typeof x T1 -> typeof (E x) T2).

tuple : list term -> term. product : list typ -> typ.
typeof (tuple ES) (product TS) :- map typeof ES TS.

eval : term -> term -> prop.
eval (lam T F) (lam T F).
eval (tuple ES) (tuple VS) :- map eval ES VS.
eval (app E E') V'' :- eval E (lam _ F), eval E' V', eval (F V') V''.
%end.


%extend stlc.
onat : typ. ozero : term. osucc : term -> term.
typeof ozero onat.
typeof (osucc N) onat :- typeof N onat.
eval ozero ozero.
eval (osucc E) (osucc V) :- eval E V.

add : term -> term -> term.
mult : term -> term -> term.

typeof (add N1 N2) onat :- typeof N1 onat, typeof N2 onat.
typeof (mult N1 N2) onat :- typeof N1 onat, typeof N2 onat.

do_oadd : term -> term -> term -> prop.
do_oadd ozero N N.
do_oadd (osucc N) N' (osucc N'') :- do_oadd N N' N''.

do_omult : term -> term -> term -> prop.
do_omult ozero N ozero.
do_omult (osucc ozero) N N.
do_omult (osucc (osucc N)) N' N''' :-
 do_omult (osucc N) N' N'',
 do_oadd N' N'' N'''.

eval (add E1 E2) V :- eval E1 V1, eval E2 V2, do_oadd V1 V2 V.
eval (mult E1 E2) V :- eval E1 V1, eval E2 V2, do_omult V1 V2 V.

aq : index -> term.
%end.
```
-->

STUDENT. Time to add STLC terms as `object`s and their types as `class`es. We can
then give the corresponding rule for `classof`. And I think that's it for the typing rules!

```makam
obj_term : stlc.term -> object. cls_typ : stlc.typ -> class.
classof (obj_term E) (cls_typ T) :- stlc.typeof E T.
stlc.typeof (stlc.aq I) T :- classof_index I (cls_typ T).
```

\begin{scenecomment}
(Hagop transcribes the example from before. Writing out the term takes several lines, so he finds himself
wishing that Makam supported some way to write terms of object languages in their native syntax.)
\end{scenecomment}

```
typeof (letrec (bind (fun power => body ([ ..long term.. ], power)))) T ?
>> Yes:
>> T := arrow onat (liftclass (cls_typ (stlc.arrow stlc.onat stlc.onat))).
```

<!--
```makam
typeof (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.ozero))))
    )], power)))) T ?
>> Yes:
>> T := arrow onat (liftclass (cls_typ (stlc.arrow stlc.onat stlc.onat))).
```

```makam
typeof (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
    (case_or_else n
      (patt_osucc patt_var)
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.mult x (stlc.app (stlc.aq i) x))))))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.ozero))))
    )
    )], power)))) T ?
>> Yes:
>> T := arrow onat (liftclass (cls_typ (stlc.arrow stlc.onat stlc.onat))).
```
-->

ADVISOR. That's great! The only thing missing to try out an evaluation example too is implementing `subst_obj`. Thanks to `structural_recursion` though, that is very easy:

```makam
subst_obj_aux, subst_obj_cases : [Any]
  (Var: index) (Replacement: object) (Where: Any) (Result: Any) -> prop.
subst_obj I_Term O Term_OforI :-
  (i:index -> subst_obj_aux i O (I_Term i) Term_OforI).

subst_obj_aux Var Replacement Where Result :-
  if (subst_obj_cases Var Replacement Where Result)
  then success
  else (structural_recursion @(subst_obj_aux Var Replacement) Where Result).
subst_obj_cases Var (obj_term Replacement) (stlc.aq Var) Replacement.
```

\noindent
My definition here is quite subtle, so let me walk you through it. First, we extend the
`subst_obj` predicate to work on any type -- that's what `subst_obj_aux` is for.
We set up the structural recursion, by attempting to see whether the "essential" cases
actually apply -- those are captured in the `subst_obj_cases` predicate. If they don't,
that means we should proceed by structural recursion. I did not mention it before, but
the `@` notation that we used to treat a polymorphic constant as a term of type `forall A T`
can be used with an arbitrary term as well, to assign it such a type if possible.
Finally, the essential case itself is a direct transcription of the pen-and-paper version.

STUDENT. Let me go and reread that a little. (...) I think it makes sense now. Well, is that all?
Are we done?

```
eval (letrec (bind (fun power => body ([ (* .. definition of power *) ],
        (* body of letrec: *) app power (osucc (osucc ozero)))))) V ?
>> Yes!!!
>> V := < obj_term (λx.x * ((λa.a * (λb.1) a) x)) >.
```

<!--
```makam
eval (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
    (case_or_else n
      (patt_osucc patt_var)
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.mult x (stlc.app (stlc.aq i) x))))))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.ozero))))
    )
    )], app power (osucc (osucc ozero)))))) V ?
>> Yes:
>> V := liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.mult x (stlc.app (stlc.lam stlc.onat (fun a => stlc.mult a (stlc.app (stlc.lam stlc.onat (fun b => stlc.osucc stlc.ozero)) a))) x)))).

(eval (letrec
  (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) 
        (* |-> *) (vbody (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.osucc stlc.ozero)))))
    (case_or_else n
      (patt_osucc patt_var)
        (* |-> *) (vbind (fun n' => vbody (
           letobj (app power n')
           (fun i =>
             liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.mult x (stlc.app (stlc.aq i) x))))))))
      (liftobj (obj_term (stlc.lam stlc.onat (fun x => stlc.ozero))))
    )
    )], app power (osucc (osucc ozero))
    )))) (liftobj (obj_term _V)),
  stlc.eval (stlc.app _V (stlc.osucc (stlc.osucc stlc.ozero))) V') ?
>> Yes:
>> V' := stlc.osucc (stlc.osucc (stlc.osucc (stlc.osucc stlc.ozero))).
```
-->

ADVISOR. See, even the Makam REPL is excited\footnote{We have taken the liberty here to transcribe the result to more meaningful syntax to make it easier to verify.}! That looks correct, even though there are a lot
of administrative redices. We should be able to fix that with the next kind of object in our check-list, though: open STLC terms! That way, instead of having `power` return an object containing a lambda function, it can return an
open term. Here's how I would write the same example from before:

```
let power_aux (n: onat): < [ stlc.onat ] stlc.onat > =
  match n with
    0 => < [x]. 1 >
  | S n' => letobj I = power_aux n' in < [x]. stlc.mult ~(I/[x]) x >
```

\noindent
We have to list out explicitly the variables that an open term depends on, so that's the
`[x].` notation I use. Then, we can use contextual types \citep{nanevski2008contextual} for the type of those open terms.

STUDENT. Good thing I've already printed the paper out. (...) OK, so it says here that we can use
contextual types to record, at the type level, the context that open terms depend on. So let's say
an open `stlc.term` of type $t$ that mentions variables of a $\Delta$ context would have a contextual
type of the form $[\Delta] t$. This is some sort of modal typing, with a precise context.

ADVISOR. Right. We now get to the tricky part: referring to variables that stand for open
terms within other terms! You know what those are, right? Those are Object-level
Object-level Meta-variables.

STUDENT. My head hurts; I'm getting [OOM](https://en.wikipedia.org/wiki/Out_of_memory) errors. Maybe
this is easier to implement in Makam than to talk about.

ADVISOR. Maybe so. Well, let me just say this: those variables will stand for open terms that depend
on a specific context $\Delta$, but we might use them at a different context $\Delta'$. We need a
*substitution* $\sigma$ to go from the context of definition into the current context.
I think writing down the rules on paper will help:

\vspace{-2em}
\begin{mathpar}
\begin{array}{ll}
\rulename{Ob-Ob-Syntax} & \\
\dep{o} ::= \text{...} \; | \; [x_1, \text{...}, x_n]. \stlce & \dep{c} ::= \text{...} \; | \; [\stlct_1, \text{...}, \stlct_n] \stlct \\
\stlce ::= \text{...} \; | \; \aqopen{i}/\sigma & 
\sigma ::= [\stlce_1, \text{...}, \stlce_n] \\
\end{array}
\end{mathpar}
\begin{mathpar}
\inferrule[Classof-OpenTerm]
          {\Psi; x_1 : \stlct_1, \text{...}, x_n : \stlct_n \vdash \stlce : \stlct}
          {\Psi \odash [x_1, \text{...}, x_n]. \stlce : [\stlct_1, \text{...}, \stlct_n] \stlct}

\inferrule[STLC-TypeOf-AntiquoteOpen]
          {\dep{i} : [\stlct_1, \text{...}, \stlct_n] \stlct \in \Psi \\
           \forall i.\Psi; \Delta \vdash \stlce_i : \stlct_i}
          {\Psi; \Delta \vdash \aqopen{\dep{i}}/[\stlce_1, \text{...}, \stlce_n] : \stlct}
\end{mathpar}
\begin{mathpar}
\begin{array}{l}
\rulename{SubstObj} \\
(\aqopen{\dep{i}}/\sigma)[[x_1, \text{...}, x_n]. \stlce / i] =
    \stlce[\stlce_1/x_1, \text{...}, \stlce_n/x_n] 
    \text{ if } \sigma[[x_1, \text{...}, x_n]. \stlce / i] = [\stlce_1, \text{...}, \stlce_n]
\end{array}
\end{mathpar}

STUDENT. I've seen that rule for \rulename{SubstObj} before, and it is still tricky... We need
to replace the open variables in $e$ through the substitution $\sigma = [\stlce^*_1, \text{...}, \stlce^*_n]$.
However, the terms $\stlce^*_1$ through $\stlce^*_n$ might mention the $i$ index themselves, so we first
need to apply the top-level substitution for $i$ to $\sigma$ itself! After that, we do replace the open
variables in $\stlce$.

ADVISOR. I feel that we are getting to the point where it's easier to write things
down in Makam rather than on paper:

```makam
obj_openterm : bindmany stlc.term stlc.term -> object.
cls_ctxtyp : list stlc.typ -> stlc.typ -> class.

%extend stlc.
aqopen : index -> list term -> term.
typeof (aqopen I ES) T :-
  classof_index I (cls_ctxtyp TS T), map typeof ES TS.
%end.

classof (obj_openterm XS_E) (cls_ctxtyp TS T) :-
  openmany XS_E (fun xs e => 
    assumemany stlc.typeof xs TS (stlc.typeof e T)).

subst_obj_cases I (obj_openterm XS_E) (stlc.aqopen I ES) Result :-
  subst_obj_aux I (obj_openterm XS_E) ES ES',
  applymany XS_E ES' Result.
```

STUDENT. I think that's all! This is exciting -- let me try it out:

```
(eq _TERM (letrec (bind (fun power => body ([
   lam onat (fun n =>
   case_or_else n (patt_ozero)
     (vbody (liftobj (obj_openterm (bind (fun x =>
       body (stlc.osucc stlc.ozero))))))
   (case_or_else n (patt_osucc patt_var)
     (vbind (fun n' => vbody (
       letobj (app power n') (fun i =>
       liftobj (obj_openterm (bind (fun x =>
         body (stlc.mult x (stlc.aqopen i [x])))))))))
   (liftobj (obj_openterm (bind (fun x => body stlc.ozero))))
   ))], app power (osucc (osucc ozero)))))),
  typeof _TERM T, eval _TERM V) ?
>> Yes:
>> T := liftclass (cls_ctxtyp (cons stlc.onat nil) stlc.onat),
>> V := liftobj (obj_openterm (bind (fun x => body (
          stlc.mult x (stlc.mult x (stlc.osucc stlc.ozero)))))).
```

<!--
```makam
(eq _TERM (letrec (bind (fun power => body ([
    lam onat (fun n =>
    case_or_else n
      (patt_ozero) (* |-> *)
        (vbody (liftobj (obj_openterm (bind (fun x =>
          body (stlc.osucc stlc.ozero))))))
    (case_or_else n
      (patt_osucc patt_var) (* |-> *) (vbind (fun n' => vbody (
         letobj (app power n') (fun i =>
         liftobj (obj_openterm (bind (fun x =>
           body (stlc.mult x (stlc.aqopen i [x])))))))))
      (liftobj (obj_openterm (bind (fun x => body stlc.ozero))))
    )
    )], app power (osucc (osucc ozero)))))),
  typeof _TERM T, eval _TERM V) ?
>> Yes:
>> T := liftclass (cls_ctxtyp (cons stlc.onat nil) stlc.onat),
>> V := liftobj (obj_openterm (bind (fun x => body (stlc.mult x (stlc.mult x (stlc.osucc stlc.ozero)))))).
```
-->

\noindent
It works! That's it! I cannot believe how easy this was!

AUDIENCE. We cannot possibly believe that you are claiming this was easy!

AUTHOR. Still, try implementing something like this without a metalanguage...  It takes a long time!
As a result, it limits our ability to experiment with and iterate on new language-design
ideas. That's why we started working on Makam. That took a few years, but now we can at least show
a type system like this in 27 pages of a single-column PDF!

ADVISOR. I wonder where all these voices are coming from?
