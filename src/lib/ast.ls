to-array = -> if Array.is-array it then it else [it]

copy-transitions = (from, to) ->
  Object.get-own-property-symbols(from).for-each (state) ->
    to[state] = from[state]

_node = (predicate) ->
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

_clone = (exp) ->
  states-map = {}
  transitions = {}

  Object.get-own-property-symbols(exp.transitions).for-each (state) ->
    states-map[state] = Symbol state.to-string!

  Object.get-own-property-symbols(exp.transitions).for-each (state) ->
    transitions[states-map[state]] = exp.transitions[state].map ->
      [ states-map[it.0], it.1 ]

  {
    startState: states-map[exp.start-state]
    acceptState: states-map[exp.accept-state]
    transitions: transitions
  }

_sequence = (exp) ->
  transitions = {}
  last-accept = null

  exp.for-each ->
    copy-transitions it.transitions, transitions
    transitions[last-accept] = [ [ it.start-state, null ] ] if last-accept?
    last-accept := it.accept-state

  {
    startState: exp.0.start-state
    acceptState: exp[*-1].accept-state
    transitions: transitions
  }

_or = (exp) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  transitions[start] = []

  exp.for-each ->
    copy-transitions it.transitions, transitions
    transitions[it.accept-state] = [ [ accept, null ] ]
    transitions[start].push [it.start-state, null]

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_optional = (exp) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  copy-transitions exp.transitions, transitions

  transitions[start] =
    * exp.start-state, null
    * accept, null

  transitions[exp.accept-state] =
    * accept, null
    ...

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_star = (exp) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  copy-transitions exp.transitions, transitions

  transitions[start] = transitions[exp.accept-state] =
    * exp.start-state, null
    * accept, null

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_plus = (exp) ->
  accept = Symbol \accept

  transitions = {}
  copy-transitions exp.transitions, transitions
  transitions[exp.accept-state].push do
    * exp.start-state, null
    * accept, null
  transitions[accept] = []

  {
    startState: exp.start-state
    acceptState: accept
    transitions: transitions
  }

_replicate = (exp, times) ->
  _sequence [ _clone exp for til times ]

parselets = {}

parselets.predicate = (exp) -> _node exp

parselets.value = (exp) -> _node (=== exp)

parselets.sequence = (exp) -> _sequence exp.map(parse)

parselets.or = (exp) -> _or to-array(exp.or).map(parse)

parselets.optional = (exp) -> _optional parse(exp.optional)

parselets.repeat = (exp) ->
  e = parse exp.repeat
  {min, max} = exp{min, max}
  if max > 0
    switch
    | min == max            => _replicate e, min # {2,2}
    | not min? or min <= 0  => _replicate _optional(e), max # {,5}
    | _ => # {3,7}
      required = _replicate e, min
      optional = _replicate _optional(e), max - min
      _sequence [ required, optional ]
  else
    switch
    | not min? or min == 0  => _star e # {,}
    | min == 1              => _plus e # {1,}
    | _ => _sequence [ _replicate(e, min - 1), _plus e ] # {7,}

parse = (exp) ->
  switch typeof! exp
    | \Object =>
      parselets-names = Object.get-own-property-names parselets
      for own e of exp when e in parselets-names
        return parselets[e](exp)
      parselets.value exp
    | \Array    => parselets.sequence exp
    | \Function => parselets.predicate exp
    | _         => parselets.value exp

module.exports = parse
