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
    EXTRAOPTS="-V revealjs-url:https://cdn.jsdelivr.net/gh/astampoulis/reveal.js@3.7.0-makam"
    ;;
  "xoffline")
    MODE="offline"
    OUTPUT="offline.html"
    MATHJAX="MathJax/MathJax.js?config=TeX-AMS_HTML-full"
    EXTRAOPTS="--self-contained"
    ;;
  *)
    echo "Usage: $0 <dev|online|offline>"
    exit 1
    ;;
esac

if [[ $MODE != "online" && ! -e reveal.js ]]; then
    git clone git://github.com/astampoulis/reveal.js
    (cd reveal.js; git checkout as-fixes-for-makam-webui)
fi

if [[ $MODE == "offline" && ! -e MathJax ]]; then
    git clone git://github.com/mathjax/MathJax
fi

pandoc --mathjax=$MATHJAX $EXTRAOPTS -s -t revealjs slides.md -o $OUTPUT
sed -i -r \
        -e 's@<pre class="([^"]+)"><code>@<pre><code class="language-\1">@' \
        -e 's@history: true,@history: true, keyboardCondition: (function(ev) { return ev.target.tagName == "BODY"; }),@' \
        -e '/Reveal.initialize\(\{$/ iReveal.addKeyBinding(81, function(){ webUI.reset({ animations: false }); });\n' \
        $OUTPUT

if [[ $MODE == "offline" ]]; then
  sed -i -r -e 's@https://gj20qvg6wb.execute-api.us-east-1.amazonaws.com/icfp2018talk/makam/query@http://localhost:3000/makam/query@' $OUTPUT
fi
