require! {
  './ast'
  './nfa': NFA
}

module.exports = (...expressions) ->
    matcher = new NFA ast(expressions)
    { test: (input) -> matcher.match input }
