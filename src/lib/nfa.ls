class NFA
  ({ @transitions, @start-state = \start, @accept-state = \accept }) ->

  _evaluate: (predicate, value) ~>
    if typeof! predicate isnt \Function
      p = (is predicate)
    else
      p = predicate

    p value

  _goTo: (states, value) ~>
    ret = new Set
    states.for-each (state) ~>
      @transitions[state] .filter ( ~> @_evaluate it.1, value) .map (.0) .for-each (next-state) ->
        ret.add next-state
    ret

  _closure: (states) ~>
    stack = Array.from states
    ret = new Set states
    while stack.length > 0
      state = stack.pop!
      @transitions[state] .filter (.1 is null) .map (.0) .for-each (next-state) ->
        unless next-state in ret
          ret.add next-state
          stack.push next-state
    ret

  match: (arg) ~>
    iterator = if arg[Symbol.iterator]?
      arg[Symbol.iterator]!
    else
      arg

    @current-states = @_closure(new Set [@start-state])
    next = iterator.next!

    while not next.done
      value = next.value
      g = @_go-to(@current-states, value)
      @current-states = @_closure g
      next = iterator.next!

    @current-states.has @accept-state

module.exports = NFA
