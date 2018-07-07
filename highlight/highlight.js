const mock = require("mock-require");

const modes = {};

const interpret = (description, input) => {
  var offset = 0;
  var stack = [];
  var key = "start";
  var output = "";

  while (true) {
    var matches = description[key]
      .map(rule => {
        var result = input.slice(offset).match(rule.regex);
        if (result) result.rule = rule;
        return result;
      })
      .filter(x => x !== null)
      .map(x => Object.assign(x, { index: x.index + offset }))
      .filter(
        x => (x.rule.sol ? x.index == 0 || input[x.index - 1] == "\n" : true)
      );

    if (matches.length === 0) {
      output += input.slice(offset);
      break;
    }

    var minimum = matches.reduce(
      (min, elm) => (elm.index < min.index ? elm : min)
    );

    const match = minimum[0];
    output += input.slice(offset, minimum.index);
    if (minimum.rule.token) {
      const token = minimum.rule.token
        .replace(" ", "")
        .replace("variable-2", "metavariable");
      output += `\\tok${token}{${match}}`;
    } else {
      output += match;
    }

    offset = minimum.index + match.length;

    if (minimum.rule.next) {
      key = minimum.rule.next;
    } else if (minimum.rule.push) {
      stack.push(key);
      key = minimum.rule.push;
    } else if (minimum.rule.pop) {
      key = stack.pop();
    }
  }

  return output;
};

const defineMode = (name, description) => {
  modes[name] = input => interpret(description, input);
};

const highlight = (name, input) => modes[name](input);

mock("codemirror/lib/codemirror", {
  defineSimpleMode: defineMode
});

require("./makam-codemirror");

module.exports = highlight;
