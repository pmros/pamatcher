require! '../vendor/kappa': k

grammar = (rules) -> new k.data.Grammar { rules, startSymbol: rules.0.head }
rule = (name, opts) ->
  new k.data.Rule { name, opts.head, opts.tail, reduceFunc:opts.reduce }
non-terminal = (name) -> new k.data.NonTerminal { name }
terminal = (name, body='') -> new k.data.Terminal { name, body }

id        = terminal \ID /[a-zA-Z][a-zA-Z0-9]*/
integer   = terminal \INTEGER /[0-9]+/
number    = terminal \NUMBER /\-?[0-9]+(\.[0-9]*)?/
wildcard  = terminal \WILDCARD /\*/
plus      = terminal \PLUS /\+/
question  = terminal \QUESTION /\?/
braces-open  = terminal \BRACES_OPEN /\{/
braces-close = terminal \BRACES_CLOSE /\}/
comma = terminal \COMMA /\,/
parens-open  = terminal \PARENS_OPEN /\(/
parens-close = terminal \PARENS_CLOSE /\)/
colon = terminal \COLON /:/
exclamation = terminal \EXCLAMATION /\!/
ampersand = terminal \AMPERSAND /\&/
pipe = terminal \PIPE /\|/

S = non-terminal \S
ITEM = non-terminal \ITEM
ATOM = non-terminal \ATOM
CARDINALITY = non-terminal \CARDINALITY

empty = new k.data.Symbol name: k.data.specialSymbol.EMPTY

pes-grammar = (predicates) ->
  grammar do
    * rule \S1,
        head: \S
        tail: [ S, ATOM ]
        reduce: ->
          [init, last] = it.values
          sequence = if init.sequence?
            init.sequence ++ last
          else
            [init, last]
          { sequence }
      rule \S2,
        head: \S
        tail: [ ATOM ]
        reduce: -> it.values.0
      rule \S3,
        head: \S
        tail: [ exclamation, ATOM ]
        reduce: -> { not: it.values.1 }
      rule \S4,
        head: \S
        tail: [ S, ampersand, ATOM ]
        reduce: -> { and: it.values.1 }
      rule \S5,
        head: \S
        tail: [ S, pipe, ATOM ]
        reduce: ->
          [init, _, last] = it.values
          expression = if init.or?
            init.or ++ last
          else
            [init, last]
          { or: expression }

      rule \ATOM1,
        head: \ATOM
        tail: [ ITEM ]
        reduce: -> it.values.0
      rule \ATOM2,
        head: \ATOM
        tail: [ parens-open, id, colon, S, parens-close, CARDINALITY ]
        reduce: -> it.values.3 <<< {name: it.values.1 }
      rule \ATOM3,
        head: \ATOM
        tail: [ parens-open, S, parens-close, CARDINALITY ]
        reduce: -> it.values.1

      rule \ITEM1,
        head: \ITEM
        tail: [ id, CARDINALITY ]
        reduce: -> { repeat: predicates[it.values.0] } <<< it.values.1
      rule \ITEM2,
        head: \ITEM
        tail: [ number, CARDINALITY ]
        reduce: -> { repeat: Number(it.values.0) } <<< it.values.1

      rule \CARDINALITY1,
        head: \CARDINALITY
        tail: [ empty ]
        reduce: -> { min: 1, max: 1 }
      rule \CARDINALITY2,
        head: \CARDINALITY
        tail: [ wildcard ]
        reduce: -> {}
      rule \CARDINALITY3,
        head: \CARDINALITY
        tail: [ question ]
        reduce: -> { min: 0 }
      rule \CARDINALITY4,
        head: \CARDINALITY
        tail: [ plus ]
        reduce: -> { min: 1 }
      rule \CARDINALITY5,
        head: \CARDINALITY
        tail: [ braces-open, integer, braces-close ]
        reduce: -> { min: it.values.1, max: it.values.1 }
      rule \CARDINALITY6,
        head: \CARDINALITY
        tail: [ braces-open, integer, comma, integer, braces-close ]
        reduce: -> { min: it.values.1, max: it.values.3 }
      rule \CARDINALITY7,
        head: \CARDINALITY
        tail: [ braces-open, comma, integer, braces-close ]
        reduce: -> { min: 0, max: it.values.3 }
      rule \CARDINALITY8,
        head: \CARDINALITY
        tail: [ braces-open, integer, comma, braces-close ]
        reduce: -> { min: it.values.1 }


module.exports = (pes, predicates={}) ->
  container = k.parser.parser-creator.create grammar: pes-grammar(predicates)
  container.lexer.set-stream pes
  parsing = container.parser.parse container.lexer
  throw new SyntaxError unless parsing
  parsing.current-value
