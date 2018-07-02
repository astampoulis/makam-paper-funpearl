# In which our heroes break into song and add more ML features

<!--
```makam
%use "07-structural.md".
tests: testsuite. %testsuite tests.
```
-->

\begin{scenecomment}
(Our heroes need a small break, so they work on a couple of features while improvising on a makam\footnote{Makam is the system of melodic modes of traditional Arabic and Turkish music that is also used in the Greek rembetiko. It is comprised of a set of scales, patterns of melodic development, and rules for improvisation.}. Roza is singing lyrics from the folk songs of her land, and Hagop is playing the oud. Their friend Lambros from the next office over joins them on the kemen\c{c}e.)
\end{scenecomment}

\begin{versy}
``You can skim this chapter / or skip it all the same. \\
It's mostly for completeness / since ML as a name \\
suggests some datatypes / and polymorphism too. \\
\hspace{1em} \vspace{-0.5em} \\
System F is easy, / later we might do \\
type generalizing / like Hindley-Milner too \\
but if you're feeling tired / I told you just before \\
you can take a break too / like Lambros from next door.''
\end{versy}

```makam
tforall : (typ -> typ) -> typ.
lamt : (typ -> term) -> term.
appt : term -> typ -> term.
```
\importantCodeblock{}
```makam
typeof (lamt E) (tforall T) :- (a:typ -> typeof (E a) (T a)).
typeof (appt E T) T' :- typeof E (tforall TF), eq T' (TF T).
```
\importantCodeblockEnd{}

<!--
```makam
typeof (lamt (fun a => lam a (fun x => x))) T ?
>> Yes:
>> T := tforall (fun a => arrow a a).

typeof (appt (lamt (fun a => lam a (fun x => x))) onat) T ?
>> Yes:
>> T := arrow onat onat.
```
-->

\begin{versy}
``The algebraic datatypes / caused all sorts of trouble \\
in the previous version / and since it was a double- \\
blind submission process / reviewers quite diverse \\
wonder who's the lunatic / who writes papers in verse.''
\end{versy}

```makam
datadef : type. datatype_bind : (Into: type) -> type.
datatype : (Def: datadef) (Rest: datatype_bind program) -> program.
```

\begin{versy}
``The types seem fairly easy / the constructors might be hard. \\
So let's go step by step for now / or we'll be here next March. \\
We won't support the poly-types / to keep the system simple, \\
and arguments to constructors? / They'll all take just a single.''
\end{versy}

```
   data nattree = Leaf of nat | Node of (nattree * nattree) ; rest
~> data nattree = [ ("Leaf", nat), ("Node", nattree * nattree) ] ; rest
~> data nattree = [ nat, nattree * nattree ] ; λLeaf. λNode. rest
~> data (λnattree. [nat, nattree * nattree]) ; λnattree. λLeaf. λNode. rest
~> data (λnattree. [nat, nattree * nattree]) ;
     λnattree. bind (λLeaf. bind (λNode. body rest))
~> datatype (mkdatadef (fun nattree => [nat, nattree * nattree]))
     (bind_datatype (fun nattree =>
       bind (fun leaf => bind (fun node => body rest))))
```

\begin{versy}
``Sometimes it just is better / to avoid all those words. \\
Just squint your eyes a little bit; / Hagop will strum some chords.''
\end{versy}

```makam
mkdatadef : (typ -> list typ) -> datadef.
constructor : type.
bind_datatype : (typ -> bindmany constructor A) -> datatype_bind A.
```

\begin{versy}
``We are avoiding GADTs / they're good but up the ante. \\
And we have MetaML to do / (in prose 'cause I'm no Dante.) \\
We're almost there, we need to add / the \texttt{wfprogram} clause. \\
But first we'll need an env. with types that / \texttt{constructor}s expose.''
\end{versy}

```makam
constructor_typ : (DataType: typ) (C: constructor) (ArgType: typ) -> prop.
```

\begin{versy}
``We go through the constructors / populating our new \texttt{prop}. \\
\texttt{DT} stands for datatype / -- the page is just too cropped.''
\end{versy}

\importantCodeblock{}
```makam
wfprogram (datatype (mkdatadef DT_ConstrArgTypes)
                    (bind_datatype DT_Constrs_Rest)) :-
  (dt:typ -> openmany (DT_Constrs_Rest dt) (pfun Constrs Rest =>
    assumemany (constructor_typ dt) Constrs (DT_ConstrArgTypes dt)
    (wfprogram Rest))).
```
\importantCodeblockEnd{}

\begin{versy}
``That's it, we're almost over / there's our wf-programs. \\
We can't use the constructors, though / remember \texttt{term}s and \texttt{patt}s ?''
\end{versy}

```makam
constr : (C: constructor) (Arg: term) -> term.
patt_constr : (C: constructor) (Arg: patt N N') -> patt N N'.
typeof (constr C Arg) Datatype :-
  constructor_typ Datatype C ArgType, typeof Arg ArgType.
typeof_patt (patt_constr C Arg) Datatype S S' :-
  constructor_typ Datatype C ArgType, typeof_patt Arg ArgType S S'.
```

\begin{versy}
``That's all, there's no example / please, download Makam. \\
Trust me: you can run this code / and check that all tests pass.''
\end{versy}

<!--
Example: definition of lists and append.

```makam
wfprogram
  (datatype
    (mkdatadef (fun llist =>
    [ product [] (* nil *) ,
      product [onat, llist] ]))
  (bind_datatype (fun llist => bind (fun cnil => bind (fun ccons => body
  (main
    (letrec
      (bind (fun append => body (
      [ lam llist (fun l1 => lam (T llist) (fun l2 =>
        case_or_else l1
          (patt_constr ccons (patt_tuple (pcons patt_var (pcons patt_var pnil))))
            (vbind (fun hd => vbind (fun tl => vbody (
            constr ccons (tuple [hd, app (app append tl) l2])))))
          l2)) ],
      (app (app append
        (constr ccons (tuple [ozero, constr cnil (tuple [])])))
        (constr ccons (tuple [ozero, constr cnil (tuple [])]))))))))))))) ?
>> Yes:
>> T := fun llist => llist.
```

We also include evaluation rules for programs.

```makam
evalprogram : program -> program -> prop.
evalprogram (main E) (main V) :- eval E V.
evalprogram (lettype T E) V :- evalprogram (E T) V.
evalprogram (datatype (mkdatadef DT_ConstrArgTypes)
                      (bind_datatype DT_Constrs_Rest))
            (datatype (mkdatadef DT_ConstrArgTypes)
                      (bind_datatype DT_Constrs_Rest'))
:-
  (dt:typ -> openmany (DT_Constrs_Rest dt) (pfun Constrs Rest => [Rest']
    applymany (DT_Constrs_Rest' dt) Constrs Rest',
    assumemany (constructor_typ dt) Constrs (DT_ConstrArgTypes dt)
    (evalprogram Rest Rest'))).

eval (constr C Arg) (constr C Arg') :- eval Arg Arg'.
match (patt_constr C P) (constr C V) Subst Subst' :-
  match P V Subst Subst'.

evalprogram
  (datatype
    (mkdatadef (fun llist =>
    [ product [] (* nil *) ,
      product [onat, llist] ]))
  (bind_datatype (fun llist => bind (fun cnil => bind (fun ccons => body
  (main
    (letrec
      (bind (fun append => body (
      [ lam llist (fun l1 => lam _ (fun l2 =>
        case_or_else l1
          (patt_constr ccons (patt_tuple (pcons patt_var (pcons patt_var pnil))))
            (vbind (fun hd => vbind (fun tl => vbody (
            constr ccons (tuple [hd, app (app append tl) l2])))))
          l2)) ],
      (app (app append
        (constr ccons (tuple [ozero, constr cnil (tuple [])])))
        (constr ccons (tuple [ozero, constr cnil (tuple [])]))))))))))))) V ?
>> Yes:
>> V := (datatype (mkdatadef (fun llist => [ product [] (* nil *), product [onat, llist] ])) (bind_datatype (fun llist => bind (fun cnil => bind (fun ccons => body (main (constr ccons (tuple [ozero, constr ccons (tuple [ozero, constr cnil (tuple [])])])))))))).
```

-->
