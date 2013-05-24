// Generated by CoffeeScript 1.6.2
(function() {
  Tinytest.add("ReactiveArray - Mutator", function(test) {
    var arr, sortedArray;

    arr = new ReactiveArray;
    test.equal(arr.length, 0);
    test.equal(_.size(arr), 0);
    test.equal(arr.length = 8, 8);
    arr[3] = 'abc';
    test.equal(arr.length, 8);
    test.equal(_.size(arr), 8);
    test.equal(arr.length = 4, 4);
    test.equal(arr[3], 'abc');
    test.equal(arr.length = 0, 0);
    test.equal(arr.length, 0);
    test.equal(_.size(arr), 0);
    test.equal(arr.push('drink', 'beer', 'or', 'wine'), 4);
    test.equal(arr.length, 4);
    test.equal(_.size(arr), 4);
    test.equal(arr[0], 'drink');
    test.equal(arr[3], 'wine');
    test.isUndefined(arr[4]);
    test.equal(arr.pop(), 'wine');
    test.equal(arr.length, 3);
    test.equal(_.size(arr), 3);
    test.equal(arr.shift(), 'drink');
    test.equal(arr.length, 2);
    test.equal(_.size(arr), 2);
    test.equal(arr.unshift('give'), 3);
    test.equal(arr[0], 'give');
    test.equal(arr.splice(2), ['or']);
    test.equal(arr.length, 2);
    test.equal(_.size(arr), 2);
    test.equal(arr[0] = 'drink', 'drink');
    test.equal(arr.length, 2);
    test.equal(_.size(arr), 2);
    test.equal(arr[0], 'drink');
    sortedArray = new ReactiveArray('beer', 'drink');
    test.equal(arr.sort(), sortedArray);
    return test.equal(arr, sortedArray);
  });

  Tinytest.add("ReactiveArray - Deps", function(test) {
    var arr, bracketX, indexOfX, lastIndexOfX, lengthX;

    arr = new ReactiveArray;
    lengthX = 0;
    Deps.autorun(function() {
      var l;

      l = arr.length;
      return lengthX++;
    });
    test.equal(lengthX, 1);
    indexOfX = 0;
    Deps.autorun(function() {
      arr.indexOf('first');
      return indexOfX++;
    });
    test.equal(indexOfX, 1);
    lastIndexOfX = 0;
    Deps.autorun(function() {
      arr.lastIndexOf('last');
      return lastIndexOfX++;
    });
    test.equal(lastIndexOfX, 1);
    arr.push('my');
    Deps.flush();
    test.equal(lengthX, 2);
    test.equal(indexOfX, 2);
    test.equal(lastIndexOfX, 2);
    bracketX = 0;
    Deps.autorun(function() {
      var v;

      v = arr[0];
      return bracketX++;
    });
    test.equal(bracketX, 1);
    arr.push('first');
    Deps.flush();
    test.equal(bracketX, 1);
    test.equal(lengthX, 3);
    test.equal(indexOfX, 3);
    test.equal(lastIndexOfX, 3);
    arr.push('last');
    Deps.flush();
    test.equal(bracketX, 1);
    test.equal(lengthX, 4);
    test.equal(indexOfX, 3);
    test.equal(lastIndexOfX, 4);
    arr.push('item');
    Deps.flush();
    test.equal(bracketX, 1);
    test.equal(lengthX, 5);
    test.equal(indexOfX, 3);
    test.equal(lastIndexOfX, 5);
    arr[0] = 'your';
    Deps.flush();
    test.equal(bracketX, 2);
    test.equal(lengthX, 5);
    test.equal(indexOfX, 4, 'indexOf: needs to search again because something before the found index was changed');
    test.equal(lastIndexOfX, 5, 'lastIndexOfX: should not search again because i has a found index after the changed one');
    arr.sort();
    Deps.flush();
    test.equal(bracketX, 3);
    test.equal(lengthX, 5);
    test.equal(indexOfX, 5, 'sort changes all (not really but i\'m lazy)');
    return test.equal(lastIndexOfX, 6, 'sort changes all (not really but i\'m lazy)');
  });

  Tinytest.add("ReactiveArray - Sort/Reverse", function(test) {
    var arr, bracket1X, bracket2X;

    arr = new ReactiveArray(3, 2, 1);
    bracket1X = 0;
    Deps.autorun(function() {
      var v;

      v = arr[0];
      return bracket1X++;
    });
    test.equal(bracket1X, 1);
    bracket2X = 0;
    Deps.autorun(function() {
      var v;

      v = arr[1];
      return bracket2X++;
    });
    test.equal(bracket2X, 1);
    arr.sort();
    Deps.flush();
    test.equal(bracket1X, 2);
    test.equal(bracket2X, 1);
    arr.reverse();
    Deps.flush();
    test.equal(bracket1X, 3);
    return test.equal(bracket2X, 1);
  });

  Tinytest.add("ReactiveArray - Every/Some", function(test) {
    var arr, everyX, someX;

    arr = new ReactiveArray(1, 1, 2);
    everyX = 0;
    Deps.autorun(function() {
      arr.every(function(v, i, a) {
        test.equal(a, arr);
        test.equal(v, arr._list[i]);
        return v === 1;
      });
      return everyX++;
    });
    test.equal(everyX, 1);
    someX = 0;
    Deps.autorun(function() {
      arr.some(function(v, i, a) {
        test.equal(a, arr);
        test.equal(v, arr._list[i]);
        return v === 2;
      });
      return someX++;
    });
    test.equal(someX, 1);
    arr.push(1);
    Deps.flush();
    test.equal(everyX, 1);
    test.equal(someX, 1);
    arr.pop();
    Deps.flush();
    test.equal(everyX, 1);
    test.equal(someX, 1);
    arr.pop();
    Deps.flush();
    test.equal(everyX, 2);
    test.equal(someX, 2);
    arr.push(1);
    Deps.flush();
    test.equal(everyX, 3);
    return test.equal(someX, 3);
  });

  Tinytest.add("ReactiveArray - Map", function(test) {
    var arr, x;

    arr = new ReactiveArray(0, 1, 2);
    x = 0;
    Deps.autorun(function() {
      var map, orgMap;

      map = arr.map(function(v, i, array) {
        test.equal(array, arr);
        return v + 1;
      });
      orgMap = arr._list.map(function(v) {
        return v + 1;
      });
      test.equal(map, ReactiveArray.wrap(orgMap));
      return ++x;
    });
    test.equal(x, 1);
    arr.push(5);
    Deps.flush();
    test.equal(x, 2);
    arr.pop();
    Deps.flush();
    test.equal(x, 3);
    arr[0] = 1;
    Deps.flush();
    return test.equal(x, 4);
  });

  Tinytest.add("ReactiveArray - Reduce", function(test) {
    var arr, x;

    arr = new ReactiveArray(0, 1, 2, 3, 4);
    x = 0;
    Deps.autorun(function() {
      var orgR, r;

      r = arr.reduce(function(previousValue, currentValue, index, array) {
        test.equal(array, arr);
        return previousValue + currentValue;
      });
      orgR = arr._list.reduce(function(previousValue, currentValue) {
        return previousValue + currentValue;
      });
      test.equal(r, orgR);
      if (x === 0 || x === 2) {
        test.equal(r, 10);
      }
      if (x === 1) {
        test.equal(r, 15);
      }
      return ++x;
    });
    test.equal(x, 1);
    arr.push(5);
    Deps.flush();
    test.equal(x, 2);
    arr.pop();
    Deps.flush();
    test.equal(x, 3);
    arr[0] = 1;
    Deps.flush();
    return test.equal(x, 4);
  });

  Tinytest.add("ReactiveArray - EJSON", function(test) {
    var arr, dolly, objJson;

    arr = new ReactiveArray('a', 'b');
    dolly = arr.clone();
    test.isTrue(arr.equals(dolly), 'Clone should return a equal');
    objJson = EJSON.fromJSONValue(EJSON.toJSONValue(arr));
    test.isTrue(arr.equals(objJson), 'JSON from, to should return a equal object');
    arr.push('c');
    test.isFalse(arr.equals(objJson), 'Obj was changed this should not effect a JSON created version');
    test.isFalse(arr.equals(dolly), 'Obj was changed this should not effect a clone');
  });

}).call(this);
