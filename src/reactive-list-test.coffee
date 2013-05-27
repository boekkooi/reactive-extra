Tinytest.add "ReactiveList - added/addedAt", (test) ->
  invalidX = 0
  invalidCall = () ->
    invalidX++

  addedAtX = 0
  addedX = 0
  addedVal = 'init'
  addedIdx = 0
  callbacks =
    added: (val) ->
      test.equal val, addedVal
      addedX++
    addedAt: (val, idx) ->
      test.equal val, addedVal
      test.equal idx, addedIdx
      addedAtX++
    changed: invalidCall
    changedAt: invalidCall
    removed: invalidCall
    removedAt: invalidCall
    movedTo: invalidCall

  list = new ReactiveList('init')

  # observe: test initial added event's
  handle = list.observe callbacks
  test.equal invalidX, 0
  test.equal addedX, 1
  test.equal addedAtX, 1

  # push: test added
  addedVal = 'push'
  addedIdx = 1
  list.push addedVal
  test.equal invalidX, 0
  test.equal addedX, 2
  test.equal addedAtX, 2

  # unshift: test added
  addedVal = 'unshift'
  addedIdx = 0
  list.unshift addedVal
  test.equal invalidX, 0
  test.equal addedX, 3
  test.equal addedAtX, 3

  # splice: test added
  addedVal = 'splice1'
  addedIdx = 1
  list.splice 1, 0, 'splice1'
  test.equal invalidX, 0
  test.equal addedX, 4
  test.equal addedAtX, 4

  addedVal = 'splice2'
  addedIdx = 3
  list.splice -1, 0, 'splice2'
  test.equal invalidX, 0
  test.equal addedX, 5
  test.equal addedAtX, 5

Tinytest.add "ReactiveList - remove/removeAt", (test) ->
  invalidX = -14
  invalidCall = () ->
    invalidX++

  removedAtX = 0
  removedX = 0
  removedVal = null
  removedIdx = 0
  callbacks =
    removed: (val) ->
      test.equal val, removedVal
      removedX++
    removedAt: (val, idx) ->
      test.equal val, removedVal
      test.equal idx, removedIdx
      removedAtX++
    changed: invalidCall
    changedAt: invalidCall
    added: invalidCall
    addedAt: invalidCall
    movedTo: invalidCall

  list = new ReactiveList('shift','keep1','splice1','keep2','splice2','keep3','pop')

  handle = list.observe callbacks
  test.equal invalidX, 0, 'observer'
  test.equal removedX, 0, 'observer'
  test.equal removedAtX, 0, 'observer'

  # pop
  removedVal = 'pop'
  removedIdx = 6
  list.pop()
  test.equal invalidX, 0, 'pop'
  test.equal removedX, 1, 'pop'
  test.equal removedAtX, 1, 'pop'

  # shift
  removedVal = 'shift'
  removedIdx = 0
  list.shift()
  test.equal invalidX, 0
  test.equal removedX, 2
  test.equal removedAtX, 2

  # splice: test added
  removedVal = 'splice1'
  removedIdx = 1
  list.splice 1, 1
  test.equal invalidX, 0
  test.equal removedX, 3
  test.equal removedAtX, 3

  removedVal = 'splice2'
  removedIdx = 2
  list.splice -2, 1
  test.equal invalidX, 0
  test.equal removedX, 4
  test.equal removedAtX, 4

Tinytest.add "ReactiveList - splice", (test) ->
  addedX = addedAtX = -7
  changedX = changedAtX = 0
  removedX = removedAtX = 0
  movedX = 0

  changedRun = [
    { val: '2', newVal: 'replacement1', idx: 1 } # run 1
    { val: '4', newVal: 'replacement2', idx: 3 } # run 2
    { val: '5', newVal: 'replacement3', idx: 4 }

    { val: '3', newVal: 'replacement4', idx: 2 } # run 3
    { val: 'replacement4', newVal: 'replacement5', idx: 2 } # run 4
  ]
  addedRun = [
    { val: '3.5', idx: 3 } # run 3
  ]
  removedRun = [
    { val: '3.5', idx: 3 } # run 4
  ]
  movedRun = []

  callbacks =
    added: (val) ->
      if addedX >= 0
        eq = addedRun[addedX]
        test.equal val, eq.val, 'added - val: ' + addedX
      addedX++
    addedAt: (val, idx) ->
      if addedAtX >= 0
        eq = addedRun[addedAtX]
        test.equal val, eq.val, 'addedAt - val: ' + addedAtX
        test.equal idx, eq.idx, 'addedAt - idx: ' + addedAtX
      addedAtX++
    changed: (val, oldVal) ->
      eq = changedRun[changedX]
      test.equal val, eq.newVal, 'changed - val: ' + changedX
      test.equal oldVal, eq.val, 'changed - oldVal: ' + changedX
      changedX++
    changedAt: (val, oldVal, idx) ->
      eq = changedRun[changedAtX]
      test.equal val, eq.newVal, 'changedAt - val: ' + changedAtX
      test.equal oldVal, eq.val, 'changedAt - oldVal: ' + changedAtX
      test.equal idx, eq.idx, 'changedAt - idx: ' + changedAtX
      changedAtX++
    removed:  (val) ->
      eq = removedRun[removedX]
      test.equal val, eq.val, 'removed - val: ' + removedX
      removedX++
    removedAt: (val, idx) ->
      eq = removedRun[removedAtX]
      test.equal val, eq.val, 'removedAt - val: ' + removedAtX
      test.equal idx, eq.idx, 'removedAt - idx: ' + removedAtX
      removedAtX++
    movedTo: (val, idx) ->
      eq = movedRun[movedX]
      test.equal val, eq.val, 'movedTo - val: ' + movedX
      test.equal idx, eq.idx, 'movedTo - idx: ' + movedX
      movedX++

  list = new ReactiveList('1','2','3','4','5','6','7')

  # Attach callbacks
  list.observe callbacks
  test.equal addedX, 0, 'added: observe'
  test.equal addedAtX, 0, 'addedAt: observe'
  test.equal removedX, 0, 'removedAt: observe'
  test.equal removedAtX, 0, 'removedAt: observe'
  test.equal changedX, 0, 'changed: observe'
  test.equal changedAtX, 0, 'changedAt: observe'
  test.equal movedX, 0, 'moved: observe'

  # splice
  list.splice 1, 1, changedRun[0].newVal
  test.equal addedX, 0, 'added: run 1'
  test.equal addedAtX, 0, 'addedAt: run 1'
  test.equal removedX, 0, 'removedAt: run 1'
  test.equal removedAtX, 0, 'removedAt: run 1'
  test.equal changedX, 1, 'changed: run 1'
  test.equal changedAtX, 1, 'changedAt: run 1'
  test.equal movedX, 0, 'moved: run 1'

  # splice
  list.splice 3, 2, changedRun[1].newVal, changedRun[2].newVal
  test.equal addedX, 0, 'added: run 2'
  test.equal addedAtX, 0, 'addedAt: run 2'
  test.equal removedX, 0, 'removedAt: run 2'
  test.equal removedAtX, 0, 'removedAt: run 2'
  test.equal changedX, 3, 'changed: run 2'
  test.equal changedAtX, 3, 'changedAt: run 2'
  test.equal movedX, 0, 'moved: run 2'

  # splice
  list.splice 2, 1, changedRun[3].newVal, addedRun[0].val
  test.equal addedX, 1, 'added: run 3'
  test.equal addedAtX, 1, 'addedAt: run 3'
  test.equal removedX, 0, 'removedAt: run 3'
  test.equal removedAtX, 0, 'removedAt: run 3'
  test.equal changedX, 4, 'changed: run 3'
  test.equal changedAtX, 4, 'changedAt: run 3'
  test.equal movedX, 0, 'moved: run 3'

  # splice
  list.splice 2, 2, changedRun[4].newVal
  test.equal addedX, 1, 'added: run 4'
  test.equal addedAtX, 1, 'addedAt: run 4'
  test.equal removedX, 1, 'removedAt: run 4'
  test.equal removedAtX, 1, 'removedAt: run 4'
  test.equal changedX, 5, 'changed: run 4'
  test.equal changedAtX, 5, 'changedAt: run 4'
  test.equal movedX, 0, 'moved: run 4'

Tinytest.add "ReactiveList - reverse", (test) ->
  arr = ['1','2','3','4','5','6','7']
  arrReversed = arr.slice().reverse()
  list = ReactiveList.wrap(arr)

  list.observe
    movedTo: (val, fromIdx, toIdx) ->
      arr.splice fromIdx, 1
      arr.splice toIdx, 0, val

  test.equal list.reverse(), ReactiveList.wrap(arrReversed)
  test.equal arr, arrReversed

  list.pop()
  arr.pop()
  arrReversed.pop()
  arrReversed.reverse()
  test.equal list.reverse(), ReactiveList.wrap(arrReversed)
  test.equal arr, arrReversed

Tinytest.add "ReactiveList - sort", (test) ->
  arrs = [
    ['1','7','3','4','2','6','8','5']
    ['1','2','3','4','5','6','7'].reverse()
    ['1','7','3','7','4','2','6','8','5']
    ['1','7','3','7','7','4','7','2','6','8','5'],
    ['d', 'a', 'c', 'b', 'z', 'y', 'y']
  ]
  for arr in arrs
    arrSorted = arr.slice().sort()
    list = ReactiveList.wrap(arr)

    list.observe
      movedTo: (docVal, fromIdx, toIdx) ->
        val = (arr.splice fromIdx, 1)[0]
        test.equal val, docVal
        arr.splice toIdx, 0, val

    test.equal list.sort(), ReactiveList.wrap(arrSorted)
    test.equal arr, arrSorted
