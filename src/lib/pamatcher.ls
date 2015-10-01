require! {
  './ast': AST
  './nfa': NFA
}

class Pamatcher
  (...args) ->
    nfa = AST.sequence.apply null, args
    @matcher = new NFA nfa

  test: (input) ->
    @matcher.match input

module.exports =
  Pamatcher: Pamatcher
  sequence: AST.sequence
  or: AST.or
  repeat: AST.repeat
  optional: AST.optional
  node: AST.node
