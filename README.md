# Meteor Reactive Extra package
This is a [Meteor](http://meteor.com/) package containing reactive classes.
These classes can be used within Meteor to easily create reactive objects, dictionaries and arrays.

## Install

### Meteorite
Using [meteorite](http://oortcloud.github.io/meteorite/) do the following:
```
mrt add reactive-extra
```

### Other
If you don't like using meteorite create the folder `packages/reactive-extra/` and can copy the `packages.js` and `lib/` to it.

## ReactiveObject
A reactive object implementation.
Checkout the [api docs](http://boekkooi.github.io/reactive-extra/reactive-object.html)

### Usage

```javascript
var obj = new ReactiveObject({'foo':'1'});
obj.defineProperty('bar', 2);

obj.foo = '2';
obj.undefineProperty('foo'); // Don't use 'delete obj.foo' it will give strange results
```

## ReactiveDictionary
A reactive dictionary implementation.
Checkout the [api docs](http://boekkooi.github.io/reactive-extra/reactive-dictionary.html)

### Usage

```javascript
var obj = new ReactiveDictionary({'foo':'1'});
obj.add('bar', 2);
obj.count()
obj.foo = '2'
obj.remove('foo'); // Don't use 'delete obj.foo' it will give strange results
obj.clear();
```


## ReactiveArray
A reactive array implementation.
Checkout the [api docs](http://boekkooi.github.io/reactive-extra/reactive-array.html).

### Usage

```javascript
var arr = new ReactiveArray(1,2,3,4);
console.log arr.length
arr.map(function(v) {
    return v+1
}).toArray();

// Be aware that using 'arr[9] = "a"' won't work correctly
// A work around is to use 'arr.length = 10' and then do 'arr[9] = "a"'
```

## Cake
The current `cake` commands require the [wrench](https://github.com/ryanmcgrath/wrench-js) module, on windows the [which](https://github.com/isaacs/node-which) module is also required.

### *cake build*
This command will compile the files in `src/` to `lib/`.

### *cake example*
This command will compile the files in `src/` to `lib/`, after which it will copy `packages.js` and `lib/` to `example/packages/reactive-extra`.

### *cake docs*
This command will generate the api docs in `docs/`.
To get it working make sure you have [docco](http://jashkenas.github.io/docco/) installed.

## Todo

* Write a real example not just a placeholder for tests
* Create [Harmony Proxy](http://wiki.ecmascript.org/doku.php?id=harmony:proxies) versions of the classes
* Add `observe` and/or `observeChanges` methods when possible
* Add more test where necessary