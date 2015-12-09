class NFA
  ({ @transitions, @start-state = \start, @accept-state = \accept }) ->

  _evaluate: (predicate, value) ~>
    p = if typeof! predicate is \Function then predicate else (is predicate)
    p value

  _goTo: (states, value) ~>
    ret = new Set
    states.for-each (state) ~>
      for t in @transitions[state] when @_evaluate t.1, value
        ret.add t.0
    ret

  _closure: (states) ~>
    stack = Array.from states
    ret = new Set states
    while stack.length > 0
      state = stack.pop!
      for t in @transitions[state] when t.1 is null
        next-state = t.0
        unless next-state in ret
          ret.add next-state
          stack.push next-state
    ret

  match: (arg) ~>
    iterator = if arg[Symbol.iterator]? then arg[Symbol.iterator]! else arg

    @current-states = @_closure(new Set [@start-state])
    next = iterator.next!

    while not next.done
      value = next.value
      @current-states = @_closure @_go-to(@current-states, value)
      next = iterator.next!

    @current-states.has @accept-state

module.exports = NFA
