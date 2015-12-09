to-array = -> if Array.is-array it then it else [it]

copy-transitions = (from, to) ->
  Object.get-own-property-symbols(from).for-each (state) ->
    to[state] = from[state]

node = (predicate) ->
  start = Symbol \start
  accept = Symbol \accept
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

_clone = (a) ->
  sym-map = {}
  transitions = {}

  Object.get-own-property-symbols(a.transitions).for-each (state) ->
    sym-map[state] = Symbol state.to-string!

  Object.get-own-property-symbols(a.transitions).for-each (state) ->
    transitions[sym-map[state]] = a.transitions[state].map ->
      [ sym-map[it.0] ] ++ it.slice(1)

  {
    startState: sym-map[a.start-state]
    acceptState: sym-map[a.accept-state]
    transitions: transitions
  }

_sequence = (args) ->
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

_or = (args) ->
  start = Symbol \start
  accept = Symbol \accept

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

_optional = (a) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}

  copy-transitions a.transitions, transitions

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

_star = (a) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}

  copy-transitions a.transitions, transitions

  transitions[start] = transitions[a.accept-state] =
    * a.start-state, null
    * accept, null

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_plus = (a) ->
  accept = Symbol \accept

  transitions = {}

  copy-transitions a.transitions, transitions

  transitions[a.accept-state].push [ a.start-state, null ] [ accept, null ]

  transitions[accept] = []

  {
    startState: a.start-state
    acceptState: accept
    transitions: transitions
  }

_replicate = (a, times) ->
  args = [ _clone(a) for til times ]
  _sequence args

parselets = {}

parselets.sequence = (a) ->
  args = a.map -> parse it
  _sequence args

parselets.or = (args) ->
  args = to-array(args.or).map -> parse it
  _or args

parselets.optional = (a) ->
  _optional parse a.optional

parselets.repeat = (a) ->
  nod = parse a.repeat
  if a.max? and a.max > 0
    if a.min == a.max                     # {2,2}
      _replicate nod, a.min
    else if !a.min? or a.min <= 0         # {,5}
      _replicate _optional(nod), a.max
    else                                  # {3,7}
      required = _replicate nod, a.min
      optional =  _replicate _optional(nod), a.max - a.min
      _sequence [ required, optional ]
  else
    if !a.min? or a.min == 0              # {,}
      _star nod
    else if a.min == 1                    # {1,}
      _plus nod
    else                                  # {7,}
      _sequence [ _replicate(nod, a.min - 1), _plus nod ]

parselets.predicate = (e) -> node e

parselets.value = (e) -> node (=== e)

parse = (exp) ->
  switch typeof! exp
    case \Object
      parselets-names = Object.get-own-property-names parselets
      for own e of exp when e in parselets-names
        return parselets[e](exp)
      parselets.value exp
    case \Array
      parselets.sequence exp
    case \Function
      parselets.predicate exp
    default
      parselets.value exp

module.exports = parse
