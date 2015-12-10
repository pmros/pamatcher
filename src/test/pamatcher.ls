require! '../lib/pamatcher'

test = it
describe 'Pamatcher' !->
  test 'can match a one item sequence' !->
    matcher = pamatcher predicate: (< 10)
    result = matcher.test [ 1 ]
    expect result .to-be true

  test 'can match two items sequence' !->
    matcher = pamatcher (< 10), (> 100)
    result = matcher.test [ 1 400 ]
    expect result .to-be true

  test 'can match three items sequence' !->
    matcher = pamatcher (< 10), (> 30), (< 40)
    result = matcher.test [ 1 49 39 ]
    expect result .to-be true

  test 'can match a repeated item' !->
    matcher = pamatcher repeat: (< 10)
    result = matcher.test [ 1 3 5 6 ]
    expect result .to-be true

  test 'can match a repeated item minimum 1 time' !->
    matcher = pamatcher repeat: (< 10), min: 1
    result = matcher.test [ 1 ]
    expect result .to-be true

  test 'can match two repeated item minimum 1 time' !->
    matcher = pamatcher repeat: (< 10), min: 1
    result = matcher.test [ 1 2 ]
    expect result .to-be true

  test 'can match two repeated items minimum 2 times' !->
    matcher = pamatcher repeat: (< 10), min: 2
    result = matcher.test [ 1 2 ]
    expect result .to-be true

  test 'can match three repeated item minimum 2 times' !->
    matcher = pamatcher repeat: (< 10), min: 2
    result = matcher.test [ 1 2 3 ]
    expect result .to-be true

  test 'cannot match one repeated item minimum 2 times' !->
    matcher = pamatcher repeat: (< 10), min: 2
    result = matcher.test [ 1 ]
    expect result .to-be false

  test 'can match two repeated items exactly 2 times' !->
    matcher = pamatcher repeat: (< 10), min: 2, max: 2
    result = matcher.test [ 1 2 ]
    expect result .to-be true

  test 'cannot match one repeated item exactly 2 times' !->
    matcher = pamatcher repeat: (< 10), min: 2, max: 2
    result = matcher.test [ 1 ]
    expect result .to-be false

  test 'cannot match three repeated item exactly 2 times' !->
    matcher = pamatcher repeat: (< 10), min: 2, max: 2
    result = matcher.test [ 1 2 3 ]
    expect result .to-be false

  test 'can match one repeated item maximum 2 times' !->
    matcher = pamatcher repeat: (< 10), max: 2
    result = matcher.test [ 1 ]
    expect result .to-be true

  test 'can match two repeated item maximum 2 times' !->
    matcher = pamatcher repeat: (< 10), max: 2
    result = matcher.test [ 1 2 ]
    expect result .to-be true

  test 'cannot match three repeated items maximum 2 times' !->
    matcher = pamatcher repeat: (< 10), max: 2
    result = matcher.test [ 1 2 3 ]
    expect result .to-be false

  test 'can match two repeated items min 2 times max 3 times' !->
    matcher = pamatcher repeat: (< 10), min: 2, max: 3
    result = matcher.test [ 1 2 ]
    expect result .to-be true

  test 'can match three repeated items min 2 times max 3 times' !->
    matcher = pamatcher repeat: (< 10), min: 2, max: 3
    result = matcher.test [ 1 2 3 ]
    expect result .to-be true

  test 'cannot match four repeated items min 2 times max 3 times' !->
    matcher = pamatcher repeat: (< 10), min: 2, max: 3
    result = matcher.test [ 1 2 3 4 ]
    expect result .to-be false

  test 'can match logical disjunction' !->
    matcher = pamatcher or: (< 10)
    result = matcher.test [ 1 ]
    expect result .to-be true

  test 'can match optional items' !->
    matcher = new pamatcher do
      (< 5)
      optional: (< 10)
      (> 100)
    result = matcher.test [ 1 120 ]
    expect result .to-be true
    result = matcher.test [ 1 6 120 ]
    expect result .to-be true

  test 'can match a complex expression' !->
    matcher = pamatcher do
      * optional: (is 123)
      * repeat: [(< 10), (> 20) ]
      * or: [ (> 100), (< 5) ]
    result = matcher.test [ 123 7 23 4 56 200 ]
    expect result .to-be true

  test 'can match like a regex' !->
    input = "abbbbbbc"
    regex = /^ab*c$/
    matcher = pamatcher do
      * \a
      * repeat: \b
      * \c
    expect matcher.test(input) .to-be regex.test(input)

  test 'can match named group on a predicate expression' !->
    input = [ 2 ]
    matcher = pamatcher { predicate: (<10), name: \catched }
    expect matcher.match(input).catched .to-equal [ 2 ]

  test 'can match a named group on a repeat expression' !->
    input = [ 1 23 43 13 2 ]
    matcher = pamatcher do
      * (<10)
      * repeat: (>10), name: \catched
      * (<5)
    expect matcher.match(input).catched .to-equal [ 23 43 13 ]

  test 'can match two named groups on a repeat expressions' !->
    input = [ 1 3 5 15 13 2 ]
    matcher = pamatcher do
      * repeat: (<10), name: \first
      * repeat: (>10), name: \second
      * (<5)
    {first, second} = matcher.match(input)
    expect first .to-equal [ 1 3 5 ]
    expect second .to-equal [ 15 13 ]

  test 'can match a named group on a sequence expression' !->
    input = [ 2 100 3 ]
    matcher = pamatcher do
      * sequence: [(<10), (>10)], name: \catched
      * (<5)
    expect matcher.match(input).catched .to-equal [ 2 100 ]

  test 'can match a named group on a or expression' !->
    input = [ 23 6 ]
    matcher = pamatcher do
      * or: [(<5), (>10)], name: \catched
      * (isnt 0)
    expect matcher.match(input).catched .to-equal [ 23 ]

  test 'can match a named group on a optional expression' !->
    input = [ 2 6 ]
    matcher = pamatcher do
      * optional: (<5), name: \catched
      * (isnt 0)
    expect matcher.match(input).catched .to-equal [ 2 ]

  test 'can match a named group on a repeated expression (one or more)' !->
    input = [ 2 1 3 6 ]
    matcher = pamatcher do
      * repeat: (<5), min: 1, name: \catched
      * (isnt 0)
    expect matcher.match(input).catched .to-equal [ 2 1 3 ]
