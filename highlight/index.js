#!/usr/bin/env node

const highlight = require("./highlight");

var pandoc = require("pandoc-filter");

const action = (type, value, format, meta) => {
  if (type === "CodeBlock") {
    const firstClass = value[0][1].length > 0 ? value[0][1][0] : "";
    if (firstClass === "nohighlight") return;
    const code = highlight("makam", value[1]);
    const result = pandoc.Para([
      pandoc.RawInline("latex", `\\begin{verbatim}\n${code}\n\\end{verbatim}`)
    ]);
    return result;
  }
};

pandoc.stdio(action);
