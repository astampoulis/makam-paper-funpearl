---
header-includes:
  <script src="https://unpkg.com/codemirror/lib/codemirror.js"></script>
  <link rel="stylesheet" href="https://unpkg.com/codemirror/lib/codemirror.css" />
  <script src="https://unpkg.com/codemirror/mode/javascript/javascript.js"></script>
  <script src="https://unpkg.com/codemirror/addon/mode/simple.js"></script>
  <script src="https://unpkg.com/codemirror/addon/runmode/runmode.js"></script>
  <script src="https://unpkg.com/codemirror/addon/display/autorefresh.js"></script>
  <script src="../highlight/makam-codemirror.js"></script>
  <script src="https://unpkg.com/makam-webui/makam-webui.js"></script>
  <link rel="stylesheet" href="slides.css" />
  <script type="text/javascript">var options = {}; options['makamLambdaURL'] = 'https://gj20qvg6wb.execute-api.us-east-1.amazonaws.com/icfp2018talk/makam/query'; options['stateBlocksEditable'] = true; options['autoRefresh'] = true; options['urlOfDependency'] = (function(filename) { return new URL("../justcode/" + filename, document.baseURI).href; }); makamWebUIOnLoad(options);</script>
transition: fade
theme: custom
history: true
width: 800
height: 600
margin: 0.025
maxScale: 1
minScale: 1
pagetitle: Makam
---

# Prototyping a Functional Language <br /> using Higher-Order Logic Programming

<div style="margin-top: 1em;">
#### A Functional Pearl on Learning the Ways of λProlog/Makam
</div>

<div style="margin-top: 3em;">
Antonis Stampoulis (Originate NYC), Adam Chlipala (MIT CSAIL)
</div>

---

# PL research ideas: <br/> implementation time ↔ ability to experiment

---

# Metalanguages help minimize implementation time

<div class="fragment" data-fragment-index="1">
- Racket
- PLT Redex
- K Framework
- Spoofax
- Ott
</div>

<div class="fragment" data-fragment-index="2" style="margin-top: 3em;">
### ... or, λProlog/Makam
</div>

<aside class="notes">
Many of these frameworks are particularly well-suited to implementing specific aspects of a language, e.g. PLT Redex and K Framework for operational semantics, Racket for sophisticated DSLs, etc.

λProlog is particularly well-suited to implementing advanced type systems. In the paper, this is what we attempt.
</aside>

---

- Simply-typed lambda calculus
- System F polymorphism
- Multi-arity functions and letrec
- Pattern matching
- Algebraic datatypes
- Type synonyms
- Heterogeneous metaprogramming
- ML-style generalization

---

# Also in the paper:

- Complex binding structures
- Structural recursion
- Use of reflective predicates
- GADT support in λProlog

---

<img src="Smyrna_Trio.jpg" />

---

### Let's write some Makam!

---

```makam-hidden
tests : testsuite. %testsuite tests.
%use "00-adapted-stdlib.makam".
```

```makam
term : type.
typ : type.
typeof : term -> typ -> prop.
```

---

$$t := t_1 t_2$$
$$\tau := \tau_1 \to \tau_2$$

```makam
app : term -> term -> term.
arrow : typ -> typ -> typ.
```

---

$$\frac{\Gamma, x : \tau \vdash e : \tau'}{\Gamma \vdash \lambda x : \tau.e : \tau \to \tau'}$$

```makam
lam : typ -> (term -> term) -> term.

typeof (lam T X_E) (arrow T T') :-
  (x:term -> typeof x T -> typeof (X_E x) T').

typeof (lam _ (fun x => x)) T ?
```
```makam-hidden
>> Yes:
>> T := arrow T1 T1.
```

---

---

Tests:

```makam-input
run_tests X ?
```
