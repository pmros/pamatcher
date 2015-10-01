type = Symbol 'type'

AST = {}

AST.node = (predicate) ->
  start = Symbol 'start'
  accept = Symbol 'accept'
  {
    (type): true
    startState: start
    acceptState: accept
    transitions:
      (start):
        * accept, predicate
        ...
      (accept):
        ...
  }

is-AST = -> it[type] is true
to-node = -> if is-AST it then it else AST.node it
copy-transitions = (from, to) ->
  Object.get-own-property-symbols(from).for-each (state) ->
    to[state] = from[state]

AST.or = (...args) ->
  args = args.map -> to-node it

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
    (type): true
    startState: start
    acceptState: accept
    transitions: transitions
  }

AST.optional = (a) ->
  a = to-node a

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
    (type): true
    startState: start
    acceptState: accept
    transitions: transitions
  }

AST.opt = AST.optional

AST.repeat = (a) ->
  a = to-node a

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
    (type): true
    startState: start
    acceptState: accept
    transitions: transitions
  }

AST.rep = AST.repeat

AST.sequence = (...args) ->
  args = args.map -> to-node it

  transitions = {}
  last-accept = null

  args.for-each ->
    copy-transitions it.transitions, transitions
    transitions[last-accept] = [ [ it.start-state, null ] ] if last-accept?
    last-accept := it.accept-state

  {
    (type): true
    startState: args[0].start-state
    acceptState: args[*-1].accept-state
    transitions: transitions
  }

AST.seq = AST.sequence

module.exports = AST
