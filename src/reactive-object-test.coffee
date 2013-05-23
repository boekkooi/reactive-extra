# ###  ReactiveObject Basic Tests
Tinytest.add "ReactiveObject - Basic", (test) ->
  # Empty constructor
  obj = new ReactiveObject()
  for prop of obj when obj.hasOwnProperty prop
    test.fail
      message: 'Object should be empty and not contain ' + prop

  # Define property without value
  obj.defineProperty 'test'
  test.isTrue 'test' of obj
  test.isUndefined obj[test]

  # Define property with value
  val = ['test']
  obj.defineProperty 2, val
  test.isTrue 2 of obj, 'Integer as prop'
  test.equal obj[2], val

  # Check object properties
  test.equal _.intersection(_.keys(obj), ['test', '2']).length, 2, 'The properties of the object are incorrect'

  # Delete
  obj.undefineProperty 2
  test.isFalse 2 of obj, 'Integer as prop'
  test.isTrue 'test' of obj
  test.isUndefined obj[2]

  # Redefine without value
  obj.defineProperty 2
  test.isTrue 2 of obj, 'Integer as prop'
  test.isUndefined obj[2]

  # **Delete in a bad way do not do this**
  delete obj['test']
  test.isUndefined obj['test']
  return

# ###  ReactiveObject Dependency Tests
Tinytest.add "ReactiveObject - Deps", (test) ->
  fooVal = 'bar'
  obj = new ReactiveObject
    'foo': fooVal
    'try': 1
  test.equal _.intersection(_.keys(obj), ['foo', 'try']).length, 2, 'The properties of the object are incorrect'

  x = 0;
  Deps.autorun () ->
    test.equal fooVal, obj.foo
    ++x

  Deps.flush();
  test.equal fooVal, obj.foo
  test.equal x, 1

  obj.foo = fooVal = 'beer'
  Deps.flush();
  test.equal x, 2

  obj.try = 2
  Deps.flush();
  test.equal x, 2

  delete obj.foo
  obj.defineProperty 'foo', fooVal
  Deps.flush();
  test.equal x, 3, 'Dependency should still exists if delete is used'

  fooVal = undefined
  obj.undefineProperty 'foo'
  Deps.flush();
  test.equal x, 4, 'Dependency should be trigger on undefineProperty'

  fooVal = '2'
  obj.defineProperty 'foo', fooVal
  Deps.flush();
  test.equal x, 4, 'Dependency should be removed by undefineProperty'
  return

Tinytest.add "ReactiveObject - EJSON", (test) ->
  obj = new ReactiveObject
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