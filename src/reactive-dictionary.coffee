# ## *Reactive Dictionary*
# Represents a collection of keys and values.
#
# Example
#
# ```javascript
# ```
class @ReactiveDictionary extends ReactiveObject
  # ### constructor
  #
  # **properties** array or object with initial properties
  constructor: () ->
    # Dependency for key changes to the dictionary
    @_definePrivateProperty '_itemsKeyDep', new Deps.Dependency()

    # Dependency for value changes to the dictionary
    @_definePrivateProperty '_itemsValueDep', new Deps.Dependency()

    super

  # ### add
  # Adds the specified key and value to the dictionary.
  #
  # **key** string as the key to add
  # **value** mixed as the value to assign
  add: (key, value) ->
    throw 'An element with Key '+key+' already exists.' if key in @
    @defineProperty key, value

  # ### remove
  # Removes the value with the specified key from the Dictionary.
  #
  # **key** string as the key to remove
  remove: (key) ->
    @undefineProperty key

  # ### clear
  # Removes all keys and values from the Dictionary.
  clear: () ->
    self = @
    deps = @_itemsDeps

    _.each @_items, (v, prop) ->
      delete self[prop]
    @_items = {}
    @_itemsDeps = {}

    _.invoke deps, 'changed'
    @_itemsKeyDep.changed()
    @_itemsValueDep.changed()

  # ### count()
  # Gets the number of elements contained in the Dictionary
  count: () ->
    @_itemsKeyDep.depend()
    return _.size(@_items)

  # ### keys
  # Gets an Array containing the keys of the Dictionary.
  keys: () ->
    @_itemsKeyDep.depend()
    _.keys(@_items)

  # ### values
  # Gets an Array containing the values of the Dictionary.
  values: () ->
    @_itemsValueDep.depend()
    _.values(@_items)

  # ### contains
  # Determines whether the Dictionary contains the specified key.
  #
  # **key** string as the key to locate
  contains: (key) ->
    if _.has @_items, key
      @_propertyGet key
      return true
    @_itemsKeyDep.depend()
    false

  # ### containsValue
  # Determines whether the Dictionary contains a specific value.
  #
  # **value** mixed as the value to locate
  containsValue: (value) ->
    for key, val of @_items when _.has(@_items, key) and _.isEqual(val, value)
      @_propertyGet key
      return true
    @_itemsValueDep.depend()
    false

  # ### *[ReactiveObject Overrides](reactive-object.html)*
  # ---------------------------------------
  # #### defineProperty
  defineProperty: () ->
    rtn = super
    @_itemsKeyDep.changed()
    @_itemsValueDep.changed()
    rtn

  # #### undefineProperty
  undefineProperty: () ->
    rtn = super
    @_itemsKeyDep.changed()
    @_itemsValueDep.changed()
    rtn

  # #### _propertySet
  _propertySet: ->
    rtn = super
    @_itemsValueDep.changed()
    rtn

  # #### clone
  clone: () ->
    new ReactiveDictionary _.clone @_items

  # #### equals
  # **obj** object to compare
  equals: (obj) ->
    return obj? &&
      obj instanceof ReactiveDictionary &&
      _.isEqual obj._items, @_items

  # #### typeName
  typeName: () ->
    'reactive-dictionary'

# ## EJSON add ReactiveDictionary
# *[EJSON.addType](https://docs.meteor.com/#ejson_add_type)*
EJSON.addType 'reactive-dictionary', (jsonObj) ->
  new ReactiveDictionary(jsonObj)