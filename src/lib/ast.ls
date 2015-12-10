to-array = -> if Array.is-array it then it else [it]

copy-transitions = (from, to, name) ->
  Object.get-own-property-symbols(from).for-each (state) ->
    to[state] = ^^(from[state])
    if name?
      for t in to[state] when t.predicate?
        t.capture-group = [] unless t.capture-group?
        t.capture-group.push name

_node = (predicate, name) ->
  start = Symbol \start
  accept = Symbol \accept
  a = Symbol \a
  b = Symbol \b

  nfa =
    startState: start
    acceptState: accept
    transitions:
      (start):  [ { next-state: a } ]
      (a): [ { next-state: b, predicate: predicate } ]
      (b): [ { next-state: accept } ]
      (accept): []

  if name?
    nfa.transitions[start][0].start-group = name
    nfa.transitions[a][0].capture-group = [name]
    nfa.transitions[b][0].end-group = name

  nfa

_clone = (exp) ->
  states-map = {}
  transitions = {}

  Object.get-own-property-symbols(exp.transitions).for-each (state) ->
    states-map[state] = Symbol state.to-string!

  Object.get-own-property-symbols(exp.transitions).for-each (state) ->
    transitions[states-map[state]] = exp.transitions[state].map ->
      transition = {}
      transition.next-state = states-map[it.next-state]
      transition.predicate = it.predicate if it.predicate?
      transition

  {
    startState: states-map[exp.start-state]
    acceptState: states-map[exp.accept-state]
    transitions: transitions
  }

_sequence = (exp, name) ->
  start = Symbol \start
  accept = Symbol \accept
  a = exp.0.start-state
  b = exp[*-1].accept-state

  last-accept = null
  transitions = {}

  exp.for-each ->
    copy-transitions it.transitions, transitions, name
    transitions[last-accept] = [ next-state: it.start-state ] if last-accept?
    last-accept := it.accept-state

  transitions[start]  = [ next-state: a ]
  transitions[b]      = [ next-state: accept ]
  transitions[accept] = []

  if name?
    transitions[start][0]start-group = name
    transitions[b][0]end-group  = name

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }


_or = (exp, name) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  transitions[start] = []

  exp.for-each ->
    copy-transitions it.transitions, transitions, name
    transition = nextState: accept
    transition.end-group = name if name?
    transitions[it.accept-state] = [ transition ]
    transition = nextState: it.start-state
    transition.start-group = name if name?
    transitions[start].push transition


  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_optional = (exp, name) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  copy-transitions exp.transitions, transitions, name

  transitions[start] =
    * nextState: exp.start-state
    * nextState: accept

  transitions[exp.accept-state] =
    * nextState: accept
    ...

  transitions[accept] = []

  if name?
    transitions[start][0]start-group = name
    transitions[exp.accept-state][0]end-group = name

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_star = (exp, name) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  copy-transitions exp.transitions, transitions, name

  transitions[start] = [ {next-state: exp.start-state}, {next-state: accept} ]
  transitions[start][0]start-group = name if name?

  transitions[exp.accept-state] = [ { next-state: accept }, {next-state: exp.start-state} ]
  transitions[exp.accept-state][0]end-group = name if name?
  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_plus = (exp, name) ->
  start = Symbol \start
  accept = Symbol \accept

  transitions = {}
  copy-transitions exp.transitions, transitions, name

  transition =  next-state: exp.start-state
  transition.start-group = name if name?
  transitions[start] = [ transition ]

  transition =  next-state: accept
  transition.end-group = name if name?
  transitions[exp.accept-state] = [ transition, { nextState: exp.start-state } ]

  transitions[accept] = []

  {
    startState: start
    acceptState: accept
    transitions: transitions
  }

_replicate = (exp, times) ->
  _sequence [ _clone exp for til times ]

parselets = {}

parselets.predicate = (exp) -> _node exp.predicate, exp.name
parselets.value     = (exp) -> _node (=== exp.value), exp.name
parselets.sequence  = (exp) -> _sequence exp.sequence.map(parse), exp.name
parselets.or        = (exp) -> _or to-array(exp.or).map(parse), exp.name
parselets.optional  = (exp) -> _optional parse(exp.optional), exp.name

parselets.repeat = (exp) ->
  e = parse exp.repeat
  {min, max, name} = exp{min, max,name}
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
    | not min? or min == 0  => _star e, name # {,}
    | min == 1              => _plus e, name # {1,}
    | _ => _sequence [ _replicate(e, min - 1), _plus(e, name) ] # {7,}

parse = (exp) ->
  switch typeof! exp
    | \Object =>
      parselets-names = Object.get-own-property-names parselets
      for own e of exp when e in parselets-names
        return parselets[e](exp)
      parselets.value exp
    | \Array    => parselets.sequence sequence: exp
    | \Function => parselets.predicate predicate: exp
    | _         => parselets.value value: exp

module.exports = parse
