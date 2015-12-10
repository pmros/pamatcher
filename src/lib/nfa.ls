class NFA
  ({ @transitions, @start-state = \start, @accept-state = \accept }) ->
    @captures = {}

  _evaluate: (predicate, value) ~>
    p = if typeof! predicate is \Function then predicate else (is predicate)
    p value

  _go-to: (states, value) ~>
    ret = new Set
    states.for-each (state) ~>
      for t in @transitions[state]
        if @_evaluate t.predicate, value
          ret.add t.next-state
          if t.capture-group? and Array.is-array t.capture-group
            for group in t.capture-group
              @captures[group]buffer.push value
    ret

  _closure: (states) ~>
    stack = Array.from states
    ret = new Set states
    while stack.length > 0
      state = stack.pop!
      for t in @transitions[state]
        if t.start-group?
          @captures[t.start-group] = buffer: [], values: []
        if t.end-group?
          for value in @captures[t.end-group]buffer
            @captures[t.end-group]values.push value
          @captures[t.end-group]buffer = []
        if not t.predicate? and t.next-state not in ret
          ret.add t.next-state
          stack.push t.next-state
    ret

  match: (arg) ~>
    iterator = if arg[Symbol.iterator]? then arg[Symbol.iterator]! else arg

    @current-states = @_closure(new Set [@start-state])

    next = iterator.next!

    while not next.done
      value = next.value
      @current-states = @_closure @_go-to(@current-states, value)
      next = iterator.next!

    {
      test: @current-states.has @accept-state
      captures: { [name, capture.values] for name, capture of @captures }
    }

module.exports = NFA
