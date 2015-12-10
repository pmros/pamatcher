require! {
  './ast'
  './nfa': NFA
}

module.exports = (...expressions) ->
    matcher = new NFA ast(expressions)
    {
      test:  (input) -> matcher.match(input).test
      match: (input) -> matcher.match(input).captures
      exec:  (input) -> matcher.match(input)
    }
