(function(mod) {
  if (typeof exports == "object" && typeof module == "object")
    // CommonJS
    mod(require("codemirror/lib/codemirror"));
  else mod(CodeMirror);
})(function(CodeMirror) {
  "use strict";

  const identifier = /[a-z][a-zA-Z0-9_\']*(\.[a-z][a-zA-Z0-9_\']*)*/;
  const comment = { regex: /\(\*/, push: "comment", token: "comment" };
  const stdlibtype = /(list|option|bindmany|vbindmany|string|int|vector|zero|succ|typecons|typenil|forall|hlist|bindmanyterms|bool)\b/;
  const objtype = /(typ|term|constructor|object|class|index|stlc\.typ|stlc\.term)\b/;
  const stdlibconst = /(bindnil|bindcons|nil|cons|unit|true|false|dyn|clause|whenclause|success|failure|and|or|newvar|newmeta|newfmeta|newnmeta|assume|ifte|withall|once|guard|removableguard|plus|mult|lessthan|string\.append|string\.headtail|string\.initlast|string\.split_at_first|string\.explode|string\.capitalize|string\.uppercase|string\.lowercase|string\.contains|string\.readfile|string\.readcachefile|string\.writefile|string\.writecachefile|char_latin1|char_letter|print|tostring|tostring_qualified|print_string|cheapprint|print_current_metalevel|debug|debugfull|debugtypes|trace|locget|locset|refl\.lookup|refl\.open_constraints|refl\.headname|refl\.headargs|refl\.duphead|refl\.allconstants|refl\.assume_get|refl\.assume_reset|refl\.rules_get|refl\.rules_get_applicable|refl\.assume_get_applicable|refl\.isunif|refl\.isconst|refl\.isbaseterm|refl\.isfvar|refl\.isnvar|refl\.isfun|refl\.decomposeunif|refl\.recomposeunif|refl\.unifmetalevel|refl\.monotyp|refl\.typstring|refl\.statehash|refl\.getunif|refl\.absunif|cmd_newclause|cmd_newterm|cmd_many|cmd_stage|cmd_none|cmd_query|refl\.fromstring|js\.eval|eq|unify|dyn\.eq|not|or_many|and_many|unless|unless_many|assume_many|assume_many_clauses|assume_many|assumemany|either|for_least_upto|for_least_upto_aux|eqv|without_eqv_refl|clause\.applies|clause\.premise|clause\.demand|clause\.get_goal|clause\.get_guard|clause\.demand_or|clause\.demand_and|clause\.demand_case|typ\.eq|typ\.isunif|builtin\.refl\.isnvar|refl\.temp\.dyneq|refl\.islambdaunif|refl\.isnvar|mkforall|forall_private\.poly|forall_private\.polybvar|forall_private\.polyargs|instantiate|forall\.apply|forall\.apply|append|map|map|map|map|foldr|foldr_invert|foldl|foldl_invert|length|reverse|reverse_aux|catenable|concat|prefix|find|filter|filtermap|contains|unique|zip|zip|zip|snoc|list\.last|nil|cons|vector\.map|vector\.assumemany|nil|cons|nil|cons|args\.apply|args\.applyfull|string\.concat|string\.concat_backwards|string\.starts_with|string\.repeat|builtin\.print_string|print_string|expansion|expansion\.isconcrete|expansion\.str|tuple\.map|tuple\.fst|tuple\.snd|tuple\.dynlist|tuple\.ofdynlist|none|some|nil|cons|set\.remove|set\.remove_if_member|set\.member|set\.ccons|set\.merge|set\.diff|set\.to_list|nil|cons|map\.remove_if_member|map\.remove|map\.headtail|map\.empty|map\.find|map\.elem|map\.add_new|map\.add_or_update|map\.to_list|map\.raw_length|map\.from_list|map\.mapvalues|map\.union|map\.merge_onto|dyn\.call|dyn\.call|dyn\.to_args|dyn\.from_args|guardmany|guardmany_aux|demand\.aux_demand|demand\.or|demand\.and|demand\.case|demand\.case_otherwise|demand\.most_recent|log\.error|log\.warn|log\.info|log\.level|log_error|log_error_with_both_locs|log_warning|log_warning_do|log_info|log_info_do|testcase|TODO\.testcase|run_tests|run_tests|verbose_run_tests|testing_private\.handle_result|testing_private\.handle_failure|testing_private\.run_test|testing_private\.print_tests_aux|print_tests|persistent_cache.predicate|fluid\.current_value|fluid\.get|fluid\.set|fluid\.set|fluid\.modify|fluid\.inc|fluid\.current_value|nil|cons|iso\.iso|iso\.bidi|iso\.inverse|iso\.compose|iso\.forward|iso\.backward|iso\.run|isocast_def|isocast_find|isocast_find|isocast|structural|generic\.fold|refl\.sameunif|refl\.userdef\.getunif|refl\.userdef\.getunif_aux|refl\.userdef\.getunif_|refl\.userdef\.absunif|refl\.userdef\.absunif_aux|refl\.userdef\.absunif_|refl\.isbasehead|nil|cons|reified_args\.map|reified\.unifvar|reified\.term|reified\.const|reified\.bvar|reified\.nvar|reified\.lambda|refl\.isbvar|reify|reify1|reify2|reify3|reify4|reify5|reify6|reify_args|reify_var|reflect|reflect|full_reify\.reify|reify|eq_nounif|eqv_aux|eqv_args|eqv_assigned|eqv_unifvars|unif_alpha_eqv|pattern_match|pmatch_aux|freevars|freevars_aux|freevars_aux_|freevars_dontadd|unifvars|unifvars_aux|unifvars_aux_|reified_unif|nameofvar|infoofvar|bind|bindone\.varname|bindone\.open|bindone\.apply|bindone\.pair|bind|body|bindmany\.varnames|bindmany\.open|bindmany\.apply|bindmany\.applysome|bindmany\.pair|vbindmany\.body|vbindmany\.bind|vbindmany\.varnames|vbindmany\.open|vbindmany\.apply|vbindmany\.pair|concrete|concrete\.name|concrete\.lambda|concrete\.var|concrete\.bindone|concrete\.bindmany\.bind_c|concrete\.bindmany|concrete\.var_of_name|concrete\.name_of_var|concrete\.associate_name_and_var|concrete\.resolve_name_or_var|concrete\.handle_unresolved_name|concrete\.pattern_mode|concrete\.vars_in_context|concrete\.pick_name_prefix|concrete\.pick_name_prefix_userdef|concrete\.pick_name|concrete\.pick_name_userdef|concrete\.pick_namespace|concrete\.pick_namespace_userdef|concrete\.resolve|concrete\.resolve_|concrete\.resolve_aux|concrete\.resolve_conversion|concrete\.nil|concrete\.cons|concrete\.vbindmany|concrete\.names_of|concrete\.names_of_aux|peg\.bind|peg\.seq|peg\.action|peg\.choices|peg\.anychar|peg\.charclass|peg\.exact|peg\.neg|peg\.lookahead|peg\.empty|peg\.void|peg\.many|peg\.eval|peg\.assume|peg\.eval|peg\.builtin|peg\.js_builtin|peg\.inline|peg\.external|peg\.parse|peg\.rule|peg\.extern_def|peg\.get_peg_definition|peg\.get_external_peg_definition|peg\.parse|peg\.nil|peg\.cons|peg\.open_end|peg\.open_next|peg\.peg_list\.open|peg\.peg_list\.assume_many|peg\.letrec|peg\.gen_parse_js|peg\.quote_string_js|peg\.quote_term_js|peg\.quote_parse_res_js|peg\.parse_res_counter|peg\.quote_terms_js|peg\.quote_paren_term_js|peg\.quote_var_js|peg\.quote_var_counter|peg\.key_of_var|peg\.key_of|peg\.gather_used_results|peg\.gather_used_results_aux|peg\.quote_used_results_js|peg\.gen_dictionary_js_aux|peg\.gen_dictionary_js|peg\.result|peg\.jsresult|peg\.quote_expansion_js|peg\.gen_toplevel_parser_js|peg\.eval_parser_js|peg\.generated_toplevel_parser_js|peg\.gen_toplevel_parser_js_cached|peg\.def_toplevel_parser_js|peg\.def_parser_js|peg\.parse_opt|peg\.peg_list\.mapi_aux|peg\.peg_list\.mapi|peg\.peg_list\.assume_many|peg\.option|peg\.ignore|peg\.once_or_many|peg\.ws|peg\.ws_opt|peg\.ws_char|peg\.eof|peg\.eval_when|peg\.captured|peg\.nil|peg\.cons|peg\.cons|peg\.apply|peg\.apply_convert|peg\.transform|peg\.transform_convert|peg\.stringappend|peg\.stringmany|peg\.string_transform_gen_vars|peg\.expansion_to_stringprop|peg\.peg_args_change_bodytype|peg\.string_transform|pretty\.const|pretty\.anychar|pretty\.charclass|pretty\.empty|pretty\.void|pretty\.many|pretty\.choices|pretty\.captured|pretty\.nil|pretty\.cons|pretty\.cons|pretty\.unapply|pretty\.untransform|pretty\.pretty|pretty\.builtin|pretty\.rule|pretty\.pretty_args|pretty\.fresh_args|pretty\.get_pretty_definition|peg\.syntax|pretty\.syntax|syntax\.anychar|syntax\.charclass|syntax\.exact|syntax\.empty|syntax\.void|syntax\.many|syntax\.choices|syntax\.iso|syntax\.captured|syntax\.nil|syntax\.cons|syntax\.cons|syntax\.apply|syntax\.builtin|syntax\.inline|syntax\.rule|syntax\.to_peg|syntax\.to_pretty|syntax\.to_peg_args|syntax\.to_pretty_args|syntax\.transform|syntax\.parse|syntax\.parse_opt|syntax\.pretty|syntax\.run|syntax\.def_toplevel_js|syntax\.def_js|syntax\.group|syntax\.once_or_many|syntax\.option|syntax\.optunit|syntax\.list_sep|syntax\.list_sep_plus|syntax\.charcons|syntax\.charsnoc|syntax\.charmany|syntax\.char_once_or_many|syntax\.string_join|syntax\.ws_empty|syntax\.ws_space|syntax\.ws_newline|syntax\.token|syntax\.token|syntax\.token_id|makam\.baseident|makam\.ident_|makam\.ident|makam\.ident_first|makam\.ident_rest|makam\.unifident_first|makam\.unifident_rest|makam\.unifident|makam\.unifident_|makam\.string_literal_char|makam\.string_literal_|makam\.string_literal|makam\.string_literal_char_str|makam\.string_literal_str|makam\.int_literal_char|makam\.int_literal_|makam\.int_literal|makam\.antiquote|makam\.term|makam\.term_str|makam\.term_args_str|makam\.term|makam\.lambda|makam\.string_of_head|makam\.string_of_var|makam\.lambda_depth|makam\.term_arg|makam\.tarrow|makam\.tbase|makam\.tunif|makam\.typ_reified|makam\.apptyp_reified|makam\.basetyp_reified|syntax_syntax\.appl_str|syntax_syntax\.base_str|syntax_syntax\.args_str|syntax_syntax\.appl|syntax_syntax\.base|syntax_syntax\.args|syntax_syntax\.appl|syntax_syntax\.args|syntax_syntax\.choices_str|syntax_syntax\.choices|syntax_syntax\.choices_str_cached|syntax_syntax\.choices|syntax_syntax\.syndef|syntax_syntax\.syndef_str|syntax_syntax\.syndef_str_cached|syntax_syntax\.syndef|syntax_syntax\.syndef|syntax_syntax\.syndef_many|syntax_syntax\.syntax_rule_clause|syntax_rules|help|tests|body|bind|openmany|assumemany|applymany|vnil|vcons|vmap|vbody|vbind|vopenmany|vapplymany|vassumemany|vsnoc|structural_recursion|hnil|hcons|hmap|change|refl.dyn_to_hlist|refl.dyn_headargs|refl.headargs|happly|generic_fold|polyrec_foldl|findunif_aux|findunif|replaceunif|hasunif_aux|hasunif)\b/;
  const objprop = /(typeof|eval|typeof_patt|typeof_pattlist|match|matchlist|typedef|wfprogram|typeq|constructor_typ|evalprogram|classof|classof_index|subst_obj|stlc\.typeof|stlc\.eval|stlc\.do_oadd|stlc\.do_omult|subst_obj_aux|subst_obj_cases|generalize|get_types_in_environment)\b/;
  const objconst = /(app|arrow|lam|tuple|product|lammany|arrowmany|appmany|letrec|vletrec|onat|ozero|osucc|patt_var|patt_ozero|patt_osucc|patt_wild|patt_tuple|pnil|pcons|case_or_else|main|lettype|tforall|polylam|polyapp|datatype|mkdatadef|bind_datatype|constr|patt_constr|liftobj|liftclass|letobj|stlc\.app|stlc\.lam|stlc\.arrow|stlc\.tuple|stlc\.product|stlc\.onat|stlc\.ozero|stlc\.osucc|stlc\.add|stlc\.mult|stlc\.aq|obj_term|cls_typ|obj_openterm|cls_ctxtyp|stlc\.aqopen|let)\b/;

  const definition_start = (function(options) { return [
    Object.assign(
      {},
      {
        regex: stdlibconst,
        token: "stdconst"
      },
      options
    ),
    Object.assign(
      {},
      {
        regex: stdlibtype,
        token: "stdtypeid"
      },
      options
    ),
    Object.assign(
      {},
      {
        regex: objtype,
        token: "typeid"
      },
      options
    ),
    Object.assign(
      {},
      {
        regex: objprop,
        token: "propconst"
      },
      options
    ),
    Object.assign(
      {},
      {
        regex: objconst,
        token: "objconst"
      },
      options
    ),
    Object.assign(
      {},
      {
        regex: identifier,
        token: "const"
      },
      options
    )
  ]; });

  const base = [].concat(
    [
      { regex: /"(?:[^\\]|\\.)*?(?:"|$)/, token: "string" },
      { regex: /`\(/, sol: true, token: "builtin strong", next: "staging" },
      { regex: /`/, token: "string", push: "expansion" },
      { regex: /[1-9][0-9]*/, token: "number" },
      { regex: /\{[a-z]+\|/, token: "string strong", push: "freequote_brpp" },
      { regex: /\{\{/, token: "string strong", push: "freequote_brbr" },
      { regex: /\<\</, token: "string strong", push: "freequote_abab" },
      { regex: /\{/, token: "string strong", push: "freequote_br" },
      { regex: /\%[a-z]+/, token: "directive" },
      comment,
      {
        regex: /(Yes(:|\.|!+))|Impossible\.|\(Complete silence\)/,
        token: "query"
      },
      {
        regex: /\>\>/,
        sol: true,
        token: "query"
      },
      { regex: /[A-Z_][A-Za-z_\\'0-9]*/, token: "metavariable" }, //metavars
      {
        regex: /(if|then|else|when|fun|pfun)\b/,
        token: "keyword"
      }
    ],
    definition_start({ push: "definition", sol: true }),
    definition_start({}),
    [
      { regex: /(\<-|:-)/, token: "symbol", indent: true },
      { regex: /(:=|-\>)/, token: "symbol" },
      { regex: /=\>/, token: "keyword" },
      {
        regex: /(\.|\?)(\s|$)/,
        dedent: true,
        dedentIfLineStart: true
      }
    ]
  );

  CodeMirror.defineSimpleMode("makam", {
    start: base,
    staging: [].concat(
      [{ regex: /\)\./, token: "builtin strong", next: "start" }],
      base
    ),
    const_definition: [].concat(definition_start({}), [
      { regex: /:/, next: "type_in_definition" }
    ]),
    next_definition_start: [].concat(definition_start({ next: "definition" })),
    definition: [
      { regex: /\s*,\s*/, next: "const_definition" },
      { regex: /\s*:\s*/, next: "type_in_definition" },
      { regex: /\s/, pop: true }
    ],
    type_in_definition: [
      { regex: /(type|prop)\b/, token: "builtintype" },
      { regex: stdlibtype, token: "stdtypeid" },
      { regex: identifier, token: "typeid" },
      { regex: /-\>/, token: "arrowtype" },
      { regex: /[A-Z_][A-Za-z_\\'0-9]*/, token: "metavariable" }, //metavars
      { regex: /\.\ \s*/, next: "next_definition_start" },
      { regex: /\./, pop: true }
    ],
    expansion: [
      { regex: /\$\{/, push: "expansion_quote", token: "meta" },
      { regex: /\$\`/, pop: true, token: "string" },
      { regex: /\$[^\{]/, token: "string" },
      { regex: /(?:[^\\`\$]|\\.)+/, token: "string" },
      { regex: /\`/, pop: true, token: "string" }
    ],
    expansion_quote: [].concat(
      [{ regex: /\}/, pop: true, token: "meta" }],
      base
    ),
    freequote_brpp: [
      { regex: /\|\}/, token: "string strong", pop: true },
      { regex: /[^\|]+/, token: "string" },
      { regex: /\|/, token: "string" }
    ],
    freequote_brbr: [
      { regex: /\}\}/, token: "string strong", pop: true },
      { regex: /[^\}]+/, token: "string" },
      { regex: /\}/, token: "string" }
    ],
    freequote_abab: [
      { regex: /\>\>/, token: "string strong", pop: true },
      { regex: /[^\>]+/, token: "string" },
      { regex: /\>/, token: "string" }
    ],
    freequote_br: [
      { regex: /\}/, token: "string strong", pop: true },
      { regex: /[^\}]+/, token: "string" }
    ],
    comment: [
      // { regex: /\(\*/, token: "comment", push: "comment" },
      { regex: /.*\*\)/, token: "comment", pop: true },
      { regex: /.*/, token: "comment" }
    ]
  });

  CodeMirror.defineSimpleMode("makam-query-results", {
    start: [{ regex: /^(Yes(:|\.)|Impossible\.)/, mode: { spec: "makam" } }]
  });
});
