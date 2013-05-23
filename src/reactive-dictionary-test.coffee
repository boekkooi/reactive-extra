Tinytest.add "ReactiveDictionary - Basic", (test) ->
  # Empty constructor
  dict = new ReactiveDictionary()
  test.equal dict.count(), 0
  test.equal dict.keys(), []
  test.equal dict.values(), []

  # Add without value
  dict.add 'hello'
  test.equal dict.count(), 1
  test.equal dict.keys(), [ 'hello' ]
  test.equal dict.values(), [ undefined ]

  # Add with value
  val = ['can i get a ola?']
  dict.add 'hello1', val
  test.equal dict.count(), 2
  test.equal dict.keys(), [ 'hello', 'hello1' ]
  test.equal dict.values(), [ undefined, val ]
  test.isTrue dict.containsValue val
  test.isTrue dict.contains 'hello'

  # Remove
  dict.remove 'hello'
  test.equal dict.count(), 1
  test.equal dict.keys(), [ 'hello1' ]
  test.equal dict.values(), [ val ]

  # Clear
  dict.clear()
  test.equal dict.count(), 0, 'Clear should result in a empty count'
  test.equal dict.keys(), []
  test.equal dict.values(), []

Tinytest.add "ReactiveDictionary - Deps", (test) ->
  dict = new ReactiveDictionary()

  # count dep
  countX = 0
  Deps.autorun () ->
    dict.count()
    countX++
  test.equal countX, 1

  # contains dep
  containsX = 0
  Deps.autorun () ->
    dict.contains 'foo'
    containsX++
  test.equal containsX, 1

  # containsValue dep
  containsValueX = 0
  Deps.autorun () ->
    dict.containsValue 'world'
    containsValueX++
  test.equal containsValueX, 1

  # Add a variable `foo`
  dict.add 'foo', 'bar'
  Deps.flush()
  test.equal countX, 2
  test.equal containsX, 2, 'contains: was not found, run (foo)'
  test.equal containsValueX, 2, 'containsValue: value was not found, run (foo)'

  # Add a variable `hello` with value `world`
  dict.add 'hello', 'world'
  Deps.flush()
  test.equal countX, 3
  test.equal containsX, 2, 'contains: key was found, no run (world)'
  test.equal containsValueX, 3, 'containsValue: value was not found, run (world)'

  # Add another variable
  dict.add 'drink', 'beer'
  Deps.flush()
  test.equal countX, 4
  test.equal containsX, 2, 'contains: key was found, no run (beer)'
  test.equal containsValueX, 3, 'containsValue: value was found, no run (beer)'

  # Change `hello`
  dict['hello'] = 'world peace'
  Deps.flush()
  test.equal countX, 4
  test.equal containsX, 2, 'contains: key was found, no run (world peace)'
  test.equal containsValueX, 4, 'containsValue: value was changed, so run (world peace)'

  # Remove `foo`
  dict.remove 'foo'
  Deps.flush()
  test.equal countX, 5
  test.equal containsX, 3, 'contains: key was removed, so run (rm foo)'
  # *containsValueX should realy be 4 i don't want another dep in dictionary*
  test.equal containsValueX, 5, 'containsValue was not found, so should have run (rm foo)'

  # Change `drink`
  dict['drink'] = 'wine'
  Deps.flush()
  test.equal countX, 5
  test.equal containsX, 3, 'contains: no changes was changed, no run (wine)'
  test.equal containsValueX, 6, 'containsValue was not found, so should have run (wine)'

  # clear
  dict.clear()
  Deps.flush()
  test.equal countX, 6
  test.equal containsX, 4, 'contains: cleared, run (clear)'
  test.equal containsValueX, 7, 'containsValue: cleared, run (clear)'

Tinytest.add "ReactiveDictionary - EJSON", (test) ->
  obj = new ReactiveDictionary
    'foo': 'test'
    'try': 1

  dolly = obj.clone()
  test.isTrue obj.equals(dolly), 'Clone should return a equal'

  objJson = EJSON.fromJSONValue EJSON.toJSONValue obj

  test.isTrue obj.equals(objJson), 'JSON from, to should return a equal object'

  obj.defineProperty 'me', { title: 'developer' }
  test.isFalse obj.equals(objJson), 'Obj was changed this should not effect a JSON created version'
  test.isFalse obj.equals(dolly), 'Obj was changed this should not effect a clone'
  return
