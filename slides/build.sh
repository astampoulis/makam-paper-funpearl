#!/usr/bin/env bash

MATHJAX="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.2/MathJax.js?config=TeX-AMS_HTML-full"
case "x$1" in
  "xdev")
    MODE="dev"
    OUTPUT="dev.html"
    EXTRAOPTS=""
    ;;
  "xonline")
    MODE="online"
    OUTPUT="index.html"
    EXTRAOPTS="-V revealjs-url:https://rawgit.com/astampoulis/reveal.js/as-fixes-for-makam-webui"
    ;;
  "x")
    echo "Usage: $0 <dev|online>"
    exit 1
    ;;
esac

if [[ $MODE != "online" && ! -e reveal.js ]]; then
    git clone git://github.com/astampoulis/reveal.js
    (cd reveal.js; git checkout as-fixes-for-makam-webui)
fi

pandoc --mathjax=$MATHJAX $EXTRAOPTS -s -t revealjs slides.md -o $OUTPUT
# offline:
# pandoc --mathjax="MathJax/MathJax.js?config=TeX-AMS-MML_HTMLtoMML" --self-contained -s -t revealjs slides.md -o slides.html
sed -i -r \
        -e 's@<pre class="([^"]+)"><code>@<pre><code class="language-\1">@' \
        -e 's@history: true,@history: true, keyboardCondition: (function(ev) { return ev.target.tagName == "BODY"; }),@' \
        $OUTPUT
