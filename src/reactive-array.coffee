# ## *Reactive Array*
class @ReactiveArray
  constructor: () ->
    # the actual array that we proxy to
    @_definePrivateProperty '_list', []
    # list of index dependencies
    @_definePrivateProperty '_listDeps', []
    # index dependency
    @_definePrivateProperty '_listLengthDep', new Deps.Dependency()
    # value dependency
    @_definePrivateProperty '_listValueDep', new Deps.Dependency()
    # contains the current amount of properties linked with `_list`
    @_definePrivateProperty '_listPropertyLengh', 0

    # Define the length property proxy
    Object.defineProperty @, 'length',
      configurable: false
      enumerable: false
      get: () ->
        @_listLengthDep.depend()
        @_list.length
      set: (length) ->
        @_list.length = length
        @_syncIndexProxies()
        return @_list.length

    # Assign arguments
    if arguments.length > 0
      @_list = _.toArray arguments
      @_syncIndexProxies(true)

  # ### toArray
  # Returns a copy of the internal array
  toArray: () ->
    @_listLengthDep.depend()
    @_listValueDep.depend()
    return @_list.slice()

  # ### *Mutator methods*
  # ---------------------------------------
  # Optimized mutator methods for reactivity
  reverse: () ->
    # Implement a custom array sort could be usefull based on http://jsperf.com/js-array-reverse-vs-while-loop/9
    # but this works for small array's i still trust array.reverse a bit better
    Array.prototype.reverse.apply @_list
    `for (left = 0, right = this._list.length - 1; left < right; left += 1, right -= 1) {
      if (left === right) { continue; }
      if (this._listDeps[left]) { this._listDeps[left].changed(); }
      if (this._listDeps[right]) { this._listDeps[right].changed(); }
    }`
    @_listValueDep.changed()
    return @

  # #### sort
  # Sorts the elements of an array in place and returns the array.
  sort: () ->
    orgList = @_list.slice()
    Array.prototype.sort.apply @_list, arguments

    # Find the changed values and trigger there dependencies
    for dep, i in @_listDeps when dep && orgList[i] != @_list[i]
      dep.changed()
    @_listValueDep.changed()
    return @

  # ### *Accessor methods*
  # ---------------------------------------
  # Optimized accessor methods for reactivity
  #
  # #### indexOf
  # Returns the first index at which a given element can be found in the array, or -1 if it is not present.
  # Uses [_.indexOf](http://underscorejs.org/#indexOf).
  #
  # **searchElement** mixed as the element to locate in the array
  # **fromIndex** optional number as the index to start the search at
  indexOf: (searchElement, fromIndex) ->
    fromIndex = if `typeof isSorted == 'number'` then fromIndex else 0
    idx = _.indexOf(@_list, searchElement, fromIndex)
    if idx == -1
      @_listLengthDep.depend()
      @_listValueDep.depend()
    else
      for i in [fromIndex...idx+1] by 1
        @_listDeps[i] ?= new Deps.Dependency()
        @_listDeps[i].depend()
    return idx

  # #### lastIndexOf
  # Returns the last index at which a given element can be found in the array, or -1 if it is not present.
  # The array is searched backwards, starting at fromIndex.
  # Uses [_.lastIndexOf](http://underscorejs.org/#indexOf).
  #
  # **searchElement** mixed as the element to locate in the array
  # **fromIndex** optional number as the index at which to start searching backward
  lastIndexOf: (searchElement, fromIndex) ->
    fromIndex = if `typeof isSorted == 'number'` then fromIndex else @length
    idx = _.lastIndexOf(@_list, searchElement, fromIndex)
    if idx == -1
      @_listValueDep.depend()
    else
      for i in [idx...fromIndex] by 1
        @_listDeps[i] ?= new Deps.Dependency()
        @_listDeps[i].depend()
    return idx

  # ### *Iteration methods*
  # ---------------------------------------
  # Optimized iteration methods for reactivity
  #
  # #### forEach
  # Executes a provided function once per array element.
  #
  # **iterator** function to execute for each element.
  # **thisArg** object to use as `this` when executing `callback`.
  forEach: (iterator, thisArg) ->
    for i in [0...@length] by 1
      iterator.call(thisArg, @[i], i, @)
    return

  # #### every
  # Tests whether all elements in the array pass the test implemented by the provided function.
  #
  # **iterator** function to test for each element.
  # **thisArg** object to use as `this` when executing `callback`.
  every: (iterator, thisArg) ->
    for i in [0...@_list.length] by 1
      if !iterator.call thisArg, @_list[i], i, @
        @_listDeps[i] ?= new Deps.Dependency()
        @_listDeps[i].depend()
        return false

    @_listLengthDep.depend()
    @_listValueDep.depend()
    return true

  # #### some
  # Tests whether some element in the array passes the test implemented by the provided function.
  #
  # **iterator** function to test for each element.
  # **thisArg** object to use as `this` when executing `callback`.
  some: (iterator, thisArg) ->
    for i in [0...@_list.length] by 1
      if !!iterator.call thisArg, @_list[i], i, @
        @_listDeps[i] ?= new Deps.Dependency()
        @_listDeps[i].depend()
        return true

    @_listLengthDep.depend()
    @_listValueDep.depend()
    return false

  # ### *EJSON Functions*
  # ---------------------------------------
  # #### clone
  # *[EJSON::clone](http://docs.meteor.com/#ejson_type_clone)*
  clone: () ->
    @constructor.wrap @_list

  # #### equals
  # *[EJSON::equals](http://docs.meteor.com/#ejson_type_equals)*
  #
  # **obj** object to compare
  equals: (obj) ->
    return obj? &&
      obj instanceof ReactiveArray &&
      _.isEqual obj._list, @_list

  # #### typeName
  # *[EJSON::typeName](http://docs.meteor.com/#ejson_type_typeName)*
  typeName: () ->
    'reactive-array'

  # #### toJSONValue
  # *[EJSON::toJSONValue](http://docs.meteor.com/#ejson_type_toJSONValue)*
  toJSONValue: () ->
    return EJSON.toJSONValue(@_list)

  # ### *Internal Functions*
  # ---------------------------------------
  # #### _syncIndexProxies
  # Create proxy properties between the real array and the ReactiveArray
  #
  # **suppress** boolean that indicates that changed should not be called
  _syncIndexProxies: (suppress) ->
    length = @_list.length;
    if length > @_listPropertyLengh
      @_defineIndexProperty i for i in [@_listPropertyLengh...length] by 1
    else if @_listPropertyLengh > length
      for i in [length...@_listPropertyLengh] by 1
        dep = @_listDeps[i]
        delete @[i]
        delete @_list[i]
        delete @_listDeps[i]
        dep.changed() if dep
    if !suppress && @_listPropertyLengh != length
      @_listLengthDep.changed()
      @_listValueDep.changed()

    @_listPropertyLengh = @_list.length

  # ### _defineIndexProperty
  _defineIndexProperty: (i) ->
    Object.defineProperty @, i,
      configurable: true
      enumerable: true
      set: _.bind @_indexSet, @, i
      get: _.bind @_indexGet, @, i

  # ### _indexGet
  _indexGet: (i) ->
    @_listDeps[i] ?= new Deps.Dependency()
    @_listDeps[i].depend()
    @_list[i]

  # ### _indexSet
  _indexSet: (i, val) ->
    if @_list[i] != val
      @_list[i] = val
      @_listDeps[i]?.changed()
      @_listValueDep.changed()
    val

  # #### _definePrivateProperty
  # Create a configurable, writable, none enumerable property
  #
  # **name** string as the name of the property
  # **value** mixed as the value to assign
  _definePrivateProperty: (name, value) ->
    Object.defineProperty @, name,
      configurable: true
      enumerable: false
      writable: true
      value: value

# ### *Array Proxies*
# ---------------------------------------

# #### *Mutator methods*
# Create proxy methods
_.each ['pop', 'push'], (m) ->
  ReactiveArray.prototype[m] = () ->
    rtn = Array.prototype[m].apply @_list, arguments
    @_syncIndexProxies()
    rtn

_.each ['shift', 'splice', 'unshift'], (m) ->
  ReactiveArray.prototype[m] = () ->
    orgList = @_list.slice()
    rtn = Array.prototype[m].apply @_list, arguments
    @_syncIndexProxies()
    dep.changed() for dep, i in @_listDeps when dep && orgList[i] != @_list[i]
    rtn

# #### *Accessor methods*
# Create Accessor proxy methods
_.each ['concat','slice'], (m) ->
  ReactiveArray.prototype[m] = () ->
    rtn = Array.prototype[m].apply @_list, arguments
    @_listLengthDep.depend()
    @_listValueDep.depend()
    @constructor.wrap rtn

_.each ['join','toString'], (m) ->
  ReactiveArray.prototype[m] = () ->
    rtn = Array.prototype[m].apply @_list, arguments
    @_listLengthDep.depend()
    @_listValueDep.depend()
    rtn

# ### *Iteration methods*
# Create iteration proxy methods for `filter`, `map` that are using [underscore.js](http://underscorejs.org/)
_.each ['filter', 'map'], (m) ->
  ReactiveArray.prototype[m] = (iterator, thisArg) ->
    self = @
    iteratorProxy = (value, index) ->
      return iterator.call @, value, index, self

    rtn = _[m].call null, @_list, iteratorProxy, thisArg

    @_listLengthDep.depend()
    @_listValueDep.depend()

    @constructor.wrap rtn

# Create iteration proxy methods for `reduce`, `reduceRight` that are using [underscore.js](http://underscorejs.org/)
_.each ['reduce', 'reduceRight'], (m) ->
  ReactiveArray.prototype[m] = (iterator, initialValue, thisArg) ->
    self = @
    iteratorProxy = (previousValue, currentValue, index) ->
      return iterator.call @, previousValue, currentValue, index, self

    if arguments.length > 1
      rtn = _[m].call null, @_list, iteratorProxy, initialValue, thisArg
    else
      rtn = _[m].call null, @_list, iteratorProxy

    @_listLengthDep.depend()
    @_listValueDep.depend()

    rtn


# ### *Helper methods*
# ---------------------------------------
# #### wrap
# Method for wrapping a array
ReactiveArray.wrap = (arr) ->
  obj = new ReactiveArray
  obj._list = _.toArray arr
  obj._syncIndexProxies(true)
  obj

# ## EJSON add ReactiveArray
# *[EJSON.addType](https://docs.meteor.com/#ejson_add_type)*
EJSON.addType 'reactive-array', (jsonObj) ->
  ReactiveArray.wrap jsonObj