to-array = -> if Array.is-array it then it else [it]
copy-transitions = (from, to) ->
  Object.get-own-property-symbols(from).for-each (state) ->
    to[state] = from[state]

node = (predicate) ->
  start = Symbol 'start'
  accept = Symbol 'accept'
  {
    startState: start
    acceptState: accept
    transitions:
      (start):
        * accept, predicate
        ...
      (accept):
        ...
  }

parselets = {}

parselets.sequence = (a) ->
  args = a.map -> parse it

  transitions = {}
  last-accept = null

  args.for-each ->
    copy-transitions it.transitions, transitions
    transitions[last-accept] = [ [ it.start-state, null ] ] if last-accept?
    last-accept := it.accept-state

  {
    startState: args[0].start-state
    acceptState: args[*-1].accept-state
    transitions: transitions
  }

parselets.or = (args) ->
  args = to-array(args.or).map -> parse it

  start = Symbol 'start'
  accept = Symbol 'accept'

  transitions = {}

  transitions[start] = []

  args.for-each ->
    copy-transitions it.transitions, transitions
    transitions[it.accept-state] = [ [ accept, null ] ]
    transitions[start].push [it.start-state, null]

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

parselets.optional = (a) ->
  a = parse a.optional

  start = Symbol 'start'
  accept = Symbol 'accept'

  transitions = {}

  Object.get-own-property-symbols(a.transitions).for-each (state) ->
    transitions[state] = a.transitions[state]

  transitions[start] =
    * a.start-state, null
    * accept, null

  transitions[a.accept-state] =
    * accept, null
    ...

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

parselets.repeat = (a) ->
  a = parse a.repeat

  start = Symbol 'start'
  accept = Symbol 'accept'

  transitions = {}

  Object.get-own-property-symbols(a.transitions).for-each (state) ->
    transitions[state] = a.transitions[state]

  transitions[start] = transitions[a.accept-state] =
    * a.start-state, null
    * accept, null

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

parselets.predicate = (e) -> node e

parselets.value = (e) -> node (=== e)

parse = (exp) ->
  switch typeof! exp
    case \Object
      for e in Object.get-own-property-names(exp)
        if e in Object.get-own-property-names(parselets)
          return parselets[e](exp)
      parselets.value exp

    case \Array
      parselets.sequence exp

    case \Function
      parselets.predicate exp

    default
      parselets.value exp

module.exports = parse
