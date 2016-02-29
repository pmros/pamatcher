require! {
  './ast'
  './nfa': NFA
  './pes': pes-to-expressions
}


module.exports = (...args) ->
    expressions = if typeof! args.0 is \String
      [pes, predicates] = args
      pes-to-expressions pes, predicates
    else
      args

    matcher = new NFA ast(expressions)
    {
      test:  (input) -> matcher.match(input).test
      match: (input) -> matcher.match(input).captures
      exec:  (input) -> matcher.match(input)
    }
