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
comma        = terminal \COMMA /\,/
parens-open  = terminal \PARENS_OPEN /\(/
parens-close = terminal \PARENS_CLOSE /\)/
colon        = terminal \COLON /:/
exclamation  = terminal \EXCLAMATION /\!/
ampersand    = terminal \AMPERSAND /\&/
pipe         = terminal \PIPE /\|/
underscore   = terminal \UNDERSCORE /\_/
greater       = terminal \GREATER /\>/
greater-equal = terminal \GREATER_EQUAL /\>=/
lesser        = terminal \LESSER /\</
lesser-equal  = terminal \LESSER_EQUAL /\<=/
string        = terminal \STRING /\'[^']*\'/

S = non-terminal \S
ITEM = non-terminal \ITEM
ITEMS = non-terminal \ITEMS
ITEMSB = non-terminal \ITEMSB
PREDICATE = non-terminal \PREDICATE
SEQ = non-terminal \SEQ
OR = non-terminal \OR
QTY = non-terminal \QTY


pes-grammar = (predicates) ->
  grammar do
    * rule \S1,
        head: \S
        tail: [ ITEMS ]
        reduce: -> it.values.0

      rule \ITEM1,
        head: \ITEM
        tail: [ parens-open, ITEMS, parens-close ]
        reduce: -> it.values.1
      rule \ITEM2,
        head: \ITEM
        tail: [ parens-open, ITEMS, parens-close, QTY ]
        reduce: -> { repeat: it.values.1} <<< it.values.3
      rule \ITEM3,
        head: \ITEM
        tail: [ parens-open, id, colon, ITEMS, parens-close ]
        reduce: -> it.values.3 <<< {name: it.values.1}
      rule \ITEM4,
        head: \ITEM
        tail: [ parens-open, id, colon, ITEMS, parens-close, QTY ]
        reduce: ->
          { repeat: it.values.3} <<< {name: it.values.1} <<< it.values.5

      rule \ITEM5,
        head: \ITEM
        tail: [ PREDICATE ]
        reduce: -> { predicate: it.values.0 }
      rule \ITEM6,
        head: \ITEM
        tail: [ PREDICATE, QTY ]
        reduce: -> { repeat: it.values.0 } <<< it.values.1

      rule \ITEMS1,
        head: \ITEMS
        tail: [ ITEM ]
        reduce: -> it.values.0
      rule \ITEMS2,
        head: \ITEMS
        tail: [ ITEM, pipe, OR ]
        reduce: -> { or: [it.values.0] ++ it.values.2 }
      rule \ITEMS3,
        head: \ITEMS
        tail: [ ITEM, SEQ ]
        reduce: -> { sequence: [it.values.0] ++ it.values.1 }

      rule \SEQ1,
        head: \SEQ
        tail: [ ITEM ]
        reduce: -> [ it.values.0 ]
      rule \SEQ2,
        head: \SEQ
        tail: [ SEQ, ITEM ]
        reduce: -> it.values.0 ++ [ it.values.1 ]

      rule \OR1,
        head: \OR
        tail: [ ITEM ]
        reduce: -> [ it.values.0 ]
      rule \OR2,
        head: \OR
        tail: [ OR, pipe, ITEM ]
        reduce: -> it.values.0 ++ [ it.values.2 ]

      rule \PREDICATE_ID,
        head: \PREDICATE
        tail: [ id ]
        reduce: ({values}) -> predicates[values.0]
      rule \PREDICATE_ID_NOT,
        head: \PREDICATE
        tail: [ exclamation, id ]
        reduce: ({values}) -> (-> not predicates[values.1](it))
      rule \PREDICATE_NUMBER,
        head: \PREDICATE
        tail: [ number ]
        reduce: ({values}) -> (== Number(values.0))
      rule \PREDICATE_STRING,
        head: \PREDICATE
        tail: [ string ]
        reduce: ->
          string = it.values.0[1 to -2].join ''
          (== string)
      rule \PREDICATE_NOT_EQUAL_STRING,
        head: \PREDICATE
        tail: [ exclamation, string ]
        reduce: ->
          string = it.values.1[1 to -2].join ''
          (!= string)
      rule \PREDICATE_TRUE,
        head: \PREDICATE
        tail: [ underscore ]
        reduce: -> ( -> true )
      rule \PREDICATE_NOT_EQUAL_NUMBER,
        head: \PREDICATE
        tail: [ exclamation, number ]
        reduce: ->
          value = Number(it.values.1)
          (!= value)
      rule \PREDICATE_GREATER_NUMBER,
        head: \PREDICATE
        tail: [ greater, number ]
        reduce: ({values}) -> (> Number(values.1))
      rule \PREDICATE_GREATER_EQUAL_NUMBER,
        head: \PREDICATE
        tail: [ greater-equal, number ]
        reduce: ({values}) -> (>= Number(values.1))
      rule \PREDICATE6,
        head: \PREDICATE
        tail: [ lesser, number ]
        reduce: ({values}) -> (< Number(values.1))
      rule \PREDICATE7,
        head: \PREDICATE
        tail: [ lesser-equal, number ]
        reduce: ({values}) -> (<= Number(values.1))


      rule \QTY_ZERO_OR_MORE,
        head: \QTY
        tail: [ wildcard ]
        reduce: -> {}
      rule \QTY_ZERO_OR_ONE,
        head: \QTY
        tail: [ question ]
        reduce: -> { min: 0 }
      rule \QTY_ONE_OR_MORE,
        head: \QTY
        tail: [ plus ]
        reduce: -> { min: 1 }
      rule \QTY_EXACTLY,
        head: \QTY
        tail: [ braces-open, integer, braces-close ]
        reduce: -> { min: it.values.1, max: it.values.1 }
      rule \QTY6,
        head: \QTY
        tail: [ braces-open, integer, comma, integer, braces-close ]
        reduce: -> { min: it.values.1, max: it.values.3 }
      rule \QTY7,
        head: \QTY
        tail: [ braces-open, comma, integer, braces-close ]
        reduce: -> { min: 0, max: it.values.3 }
      rule \QTY8,
        head: \QTY
        tail: [ braces-open, integer, comma, braces-close ]
        reduce: -> { min: it.values.1 }


module.exports = (pes, predicates={}) ->
  container = k.parser.parser-creator.create grammar: pes-grammar(predicates)
  container.lexer.set-stream pes
  parsing = container.parser.parse container.lexer
  throw new SyntaxError unless parsing
  parsing.current-value
