Tinytest.add "ReactiveArray - Mutator", (test) ->
  # Empty constructor
  arr = new ReactiveArray
  test.equal arr.length, 0
  test.equal _.size(arr), 0

  # length assign
  test.equal arr.length = 8, 8
  arr[3] = 'abc'
  test.equal arr.length, 8
  test.equal _.size(arr), 8

  test.equal arr.length = 4, 4
  test.equal arr[3], 'abc'

  test.equal arr.length = 0, 0
  test.equal arr.length, 0
  test.equal _.size(arr), 0

  # push
  test.equal arr.push('drink', 'beer', 'or', 'wine'), 4
  test.equal arr.length, 4
  test.equal _.size(arr), 4
  test.equal arr[0], 'drink'
  test.equal arr[3], 'wine'
  test.isUndefined arr[4]

  # pop
  test.equal arr.pop(), 'wine'
  test.equal arr.length, 3
  test.equal _.size(arr), 3

  # shift
  test.equal arr.shift(), 'drink'
  test.equal arr.length, 2
  test.equal _.size(arr), 2

  # unshift
  test.equal arr.unshift('give'), 3
  test.equal arr[0], 'give'

  # splice
  test.equal arr.splice(2), ['or']
  test.equal arr.length, 2
  test.equal _.size(arr), 2

  # bracket assign (index must exists)
  test.equal arr[0] = 'drink', 'drink'
  test.equal arr.length, 2
  test.equal _.size(arr), 2
  test.equal arr[0], 'drink'

  # sort
  sortedArray = new ReactiveArray 'beer', 'drink'
  test.equal arr.sort(), sortedArray
  test.equal arr, sortedArray

Tinytest.add "ReactiveArray - Deps", (test) ->
  arr = new ReactiveArray

  # length dep
  lengthX = 0
  Deps.autorun () ->
    l = arr.length
    lengthX++
  test.equal lengthX, 1

  # indexOf dep
  indexOfX = 0
  Deps.autorun () ->
    arr.indexOf 'first'
    indexOfX++
  test.equal indexOfX, 1

  # lastIndexOf dep
  lastIndexOfX = 0
  Deps.autorun () ->
    arr.lastIndexOf 'last'
    lastIndexOfX++
  test.equal lastIndexOfX, 1

  # add first item
  arr.push 'my'
  Deps.flush()
  test.equal lengthX, 2
  test.equal indexOfX, 2
  test.equal lastIndexOfX, 2

  # bracket get dep
  bracketX = 0
  Deps.autorun () ->
    v = arr[0]
    bracketX++
  test.equal bracketX, 1

  # add second item
  arr.push 'first'
  Deps.flush()
  test.equal bracketX, 1
  test.equal lengthX, 3
  test.equal indexOfX, 3
  test.equal lastIndexOfX, 3

  # add third item
  arr.push 'last'
  Deps.flush()
  test.equal bracketX, 1
  test.equal lengthX, 4
  test.equal indexOfX, 3
  test.equal lastIndexOfX, 4

  # add fourth item
  arr.push 'item'
  Deps.flush()
  test.equal bracketX, 1
  test.equal lengthX, 5
  test.equal indexOfX, 3
  test.equal lastIndexOfX, 5

  # change first
  arr[0] = 'your'
  Deps.flush()
  test.equal bracketX, 2
  test.equal lengthX, 5
  test.equal indexOfX, 4, 'indexOf: needs to search again because something before the found index was changed'
  test.equal lastIndexOfX, 5, 'lastIndexOfX: should not search again because i has a found index after the changed one'

  # sort
  arr.sort()
  Deps.flush()
  test.equal bracketX, 3
  test.equal lengthX, 5
  test.equal indexOfX, 5, 'sort changes all (not really but i\'m lazy)'
  test.equal lastIndexOfX, 6, 'sort changes all (not really but i\'m lazy)'

  # shift
  arr.unshift('drink')
  Deps.flush()
  test.equal lengthX, 6
  test.equal bracketX, 4

  # unshift
  test.equal arr.shift(), 'drink'
  Deps.flush()
  test.equal lengthX, 7
  test.equal bracketX, 5

Tinytest.add "ReactiveArray - Sort/Reverse", (test) ->
  arr = new ReactiveArray 3, 2, 1

  bracket1X = 0
  Deps.autorun () ->
    v = arr[0]
    bracket1X++
  test.equal bracket1X, 1

  bracket2X = 0
  Deps.autorun () ->
    v = arr[1]
    bracket2X++
  test.equal bracket2X, 1

  arr.sort()
  Deps.flush()
  test.equal bracket1X, 2
  test.equal bracket2X, 1

  arr.reverse()
  Deps.flush()
  test.equal bracket1X, 3
  test.equal bracket2X, 1

Tinytest.add "ReactiveArray - Every/Some", (test) ->
  arr = new ReactiveArray 1, 1, 2

  everyX = 0
  Deps.autorun () ->
    arr.every (v,i,a) ->
      test.equal a, arr
      test.equal v, arr._list[i]
      v == 1
    everyX++
  test.equal everyX, 1

  someX = 0
  Deps.autorun () ->
    arr.some (v,i,a) ->
      test.equal a, arr
      test.equal v, arr._list[i]
      v == 2
    someX++
  test.equal someX, 1

  arr.push 1
  Deps.flush()
  test.equal everyX, 1
  test.equal someX, 1

  arr.pop()
  Deps.flush()
  test.equal everyX, 1
  test.equal someX, 1

  arr.pop()
  Deps.flush()
  test.equal everyX, 2
  test.equal someX, 2

  arr.push 1
  Deps.flush()
  test.equal everyX, 3
  test.equal someX, 3

Tinytest.add "ReactiveArray - Map", (test) ->
  arr = new ReactiveArray 0, 1, 2

  x = 0
  Deps.autorun () ->
    map = arr.map (v, i, array) ->
      test.equal array, arr
      return v+1
    orgMap = arr._list.map (v) ->
      return v+1

    test.equal map, ReactiveArray.wrap orgMap
    ++x
  test.equal x, 1

  arr.push 5
  Deps.flush()
  test.equal x, 2

  arr.pop()
  Deps.flush()
  test.equal x, 3

  arr[0] = 1
  Deps.flush()
  test.equal x, 4

Tinytest.add "ReactiveArray - Reduce", (test) ->
  arr = new ReactiveArray 0, 1, 2, 3, 4

  x = 0
  Deps.autorun () ->
    r = arr.reduce (previousValue, currentValue, index, array) ->
      test.equal array, arr
      return previousValue + currentValue
    orgR = arr._list.reduce (previousValue, currentValue) ->
      return previousValue + currentValue

    test.equal r, orgR
    test.equal r, 10 if x == 0 || x == 2
    test.equal r, 15 if x == 1
    ++x
  test.equal x, 1

  arr.push 5
  Deps.flush()
  test.equal x, 2

  arr.pop()
  Deps.flush()
  test.equal x, 3

  arr[0] = 1
  Deps.flush()
  test.equal x, 4

Tinytest.add "ReactiveArray - EJSON", (test) ->
  arr = new ReactiveArray 'a', 'b'

  dolly = arr.clone()
  test.isTrue arr.equals(dolly), 'Clone should return a equal'

  objJson = EJSON.fromJSONValue EJSON.toJSONValue arr

  test.isTrue arr.equals(objJson), 'JSON from, to should return a equal object'

  arr.push 'c'
  test.isFalse arr.equals(objJson), 'Obj was changed this should not effect a JSON created version'
  test.isFalse arr.equals(dolly), 'Obj was changed this should not effect a clone'
  return


Tinytest.add "ReactiveArray - issue 2", (test) ->
  arr = new ReactiveArray
  i = 0
  Deps.autorun () ->
    i++
    if i > 1
      return
    arr.push 'val'

  arr.push 'val'
  Deps.flush()

  if i != 1
    test.fail {message: 'This should only be called once'}

