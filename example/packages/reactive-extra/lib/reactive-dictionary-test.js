// Generated by CoffeeScript 1.7.1
(function() {
  Tinytest.add("ReactiveDictionary - Basic", function(test) {
    var dict, val;
    dict = new ReactiveDictionary();
    test.equal(dict.count(), 0);
    test.equal(dict.keys(), []);
    test.equal(dict.values(), []);
    dict.add('hello');
    test.equal(dict.count(), 1);
    test.equal(dict.keys(), ['hello']);
    test.equal(dict.values(), [void 0]);
    val = ['can i get a ola?'];
    dict.add('hello1', val);
    test.equal(dict.count(), 2);
    test.equal(dict.keys(), ['hello', 'hello1']);
    test.equal(dict.values(), [void 0, val]);
    test.isTrue(dict.containsValue(val));
    test.isTrue(dict.contains('hello'));
    dict.remove('hello');
    test.equal(dict.count(), 1);
    test.equal(dict.keys(), ['hello1']);
    test.equal(dict.values(), [val]);
    dict.clear();
    test.equal(dict.count(), 0, 'Clear should result in a empty count');
    test.equal(dict.keys(), []);
    return test.equal(dict.values(), []);
  });

  Tinytest.add("ReactiveDictionary - Deps", function(test) {
    var containsValueX, containsX, countX, dict;
    dict = new ReactiveDictionary();
    countX = 0;
    Deps.autorun(function() {
      dict.count();
      return countX++;
    });
    test.equal(countX, 1);
    containsX = 0;
    Deps.autorun(function() {
      dict.contains('foo');
      return containsX++;
    });
    test.equal(containsX, 1);
    containsValueX = 0;
    Deps.autorun(function() {
      dict.containsValue('world');
      return containsValueX++;
    });
    test.equal(containsValueX, 1);
    dict.add('foo', 'bar');
    Deps.flush();
    test.equal(countX, 2);
    test.equal(containsX, 2, 'contains: was not found, run (foo)');
    test.equal(containsValueX, 2, 'containsValue: value was not found, run (foo)');
    dict.add('hello', 'world');
    Deps.flush();
    test.equal(countX, 3);
    test.equal(containsX, 2, 'contains: key was found, no run (world)');
    test.equal(containsValueX, 3, 'containsValue: value was not found, run (world)');
    dict.add('drink', 'beer');
    Deps.flush();
    test.equal(countX, 4);
    test.equal(containsX, 2, 'contains: key was found, no run (beer)');
    test.equal(containsValueX, 3, 'containsValue: value was found, no run (beer)');
    dict['hello'] = 'world peace';
    Deps.flush();
    test.equal(countX, 4);
    test.equal(containsX, 2, 'contains: key was found, no run (world peace)');
    test.equal(containsValueX, 4, 'containsValue: value was changed, so run (world peace)');
    dict.remove('foo');
    Deps.flush();
    test.equal(countX, 5);
    test.equal(containsX, 3, 'contains: key was removed, so run (rm foo)');
    test.equal(containsValueX, 5, 'containsValue was not found, so should have run (rm foo)');
    dict['drink'] = 'wine';
    Deps.flush();
    test.equal(countX, 5);
    test.equal(containsX, 3, 'contains: no changes was changed, no run (wine)');
    test.equal(containsValueX, 6, 'containsValue was not found, so should have run (wine)');
    dict.clear();
    Deps.flush();
    test.equal(countX, 6);
    test.equal(containsX, 4, 'contains: cleared, run (clear)');
    return test.equal(containsValueX, 7, 'containsValue: cleared, run (clear)');
  });

  Tinytest.add("ReactiveDictionary - EJSON", function(test) {
    var dolly, obj, objJson;
    obj = new ReactiveDictionary({
      'foo': 'test',
      'try': 1
    });
    dolly = obj.clone();
    test.isTrue(obj.equals(dolly), 'Clone should return a equal');
    objJson = EJSON.fromJSONValue(EJSON.toJSONValue(obj));
    test.isTrue(obj.equals(objJson), 'JSON from, to should return a equal object');
    obj.defineProperty('me', {
      title: 'developer'
    });
    test.isFalse(obj.equals(objJson), 'Obj was changed this should not effect a JSON created version');
    test.isFalse(obj.equals(dolly), 'Obj was changed this should not effect a clone');
  });

}).call(this);
