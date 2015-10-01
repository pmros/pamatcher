require! '../lib/pamatcher': pm

test = it
describe 'Pamatcher' !->
  test 'can match a one item sequence' !->
    matcher = new pm.Pamatcher (< 10)
    result = matcher.test [ 1 ]
    expect result .to-be true

  test 'can match two items sequence' !->
    matcher = new pm.Pamatcher (< 10), (>100)
    result = matcher.test [ 1 400 ]
    expect result .to-be true

  test 'can match three items sequence' !->
    matcher = new pm.Pamatcher (< 10), (> 30), (<40)
    result = matcher.test [ 1 49 39 ]
    expect result .to-be true

  test 'can match a repeated item' !->
    matcher = new pm.Pamatcher pm.repeat (< 10)
    result = matcher.test [ 1 3 5 6 ]
    expect result .to-be true

  test 'can match logical disjunction' !->
    matcher = new pm.Pamatcher do
      pm.or (< 10)
    result = matcher.test [ 1 ]
    expect result .to-be true

  test 'can match optional items' !->
    matcher = new pm.Pamatcher do
      (< 5)
      pm.optional (< 10)
      (> 100)
    result = matcher.test [ 1 120 ]
    expect result .to-be true
    result = matcher.test [ 1 6 120 ]
    expect result .to-be true

  test 'can match a complex expression' !->
    matcher = new pm.Pamatcher do
      pm.optional (is 123)
      pm.repeat do
        pm.sequence (< 10), (> 20)
      pm.or (> 100), (< 5)
    result = matcher.test [ 123 7 23 4 56 3 ]
    expect result .to-be true
