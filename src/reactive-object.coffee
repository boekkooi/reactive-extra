# ## *Reactive Object*
# Represents a reactive object.
#
# Example
#
# ```javascript
# obj = new ReactiveObject(['myProp']);
# obj.defineProperty('mySecondProp');
# obj.undefineProperty('myProp');
# ```
#
# *In a perfect world we could use a [Proxy](http://wiki.ecmascript.org/doku.php?id=harmony:proxies) but this is real live...*
class @ReactiveObject
  # ### constructor
  #
  # **properties** array or object with initial properties
  constructor: (properties) ->
    @_definePrivateProperty '_items', {}

    # Object containing the dependencies of the object properties
    @_definePrivateProperty '_itemsDeps', {}

    self = @
    if _.isArray properties
      _.each properties, (prop) ->
        self.defineProperty prop, undefined
    if _.isObject properties
      _.each properties, (value, prop) ->
        self.defineProperty prop, value

  # ### defineProperty
  # Add a property
  #
  # **name** string as the property name
  defineProperty: (name, value)->
    Object.defineProperty @, name,
      configurable: true
      enumerable: true
      get: @_propertyGet.bind(@, name)
      set: @_propertySet.bind(@, name)
    @[name] = value
    return @

  # ### defineProperty
  # Remove a property
  #
  # **name** string as the property name to remove
  undefineProperty: (name) ->
    dep = @_itemsDeps[name]

    delete @[name]
    delete @_items[name]
    delete @_itemsDeps[name]

    dep.changed() if dep
    return @

  # ### *EJSON Functions*
  # ---------------------------------------
  # #### clone
  # *[EJSON::clone](http://docs.meteor.com/#ejson_type_clone)*
  clone: () ->
    new ReactiveObject _.clone @_items

  # #### equals
  # *[EJSON::equals](http://docs.meteor.com/#ejson_type_equals)*
  #
  # **obj** object to compare
  equals: (obj) ->
    return obj? &&
      obj instanceof ReactiveObject &&
      _.isEqual obj._items, @_items

  # #### typeName
  # *[EJSON::typeName](http://docs.meteor.com/#ejson_type_typeName)*
  typeName: () ->
    return 'reactive-object'

  # #### toJSONValue
  # *[EJSON::toJSONValue](http://docs.meteor.com/#ejson_type_toJSONValue)*
  toJSONValue: () ->
    return EJSON.toJSONValue(@_items)

  # ### *Internal Functions*
  # ---------------------------------------
  # #### _propertySet
  # Set the value of a property
  #
  # **name** string as the name of the property
  # **value** mixed as the value to assign
  _propertySet: (name, value) ->
    @_items[name] = value
    @_itemsDeps[name]?.changed()
    return @_items[name]

  # #### _propertyGet
  # Get the value of a property
  #
  # **name** string as the name of the property
  _propertyGet: (name) ->
    @_itemsDeps[name] ?= new Deps.Dependency()
    @_itemsDeps[name].depend()
    return @_items[name]

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

# ## EJSON add ReactiveObject
# *[EJSON.addType](https://docs.meteor.com/#ejson_add_type)*
EJSON.addType 'reactive-object', (jsonObj) ->
  new ReactiveObject(jsonObj)