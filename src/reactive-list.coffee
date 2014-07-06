# ## *Reactive List*
# Represents a reactive list extended from a ReactiveArray.
# A `ReactiveList` adds the observe function.
#
# Example
#
# ```javascript
# list = new ReactiveList('first');
# list.observer({
#   added: function(newDoc) { console.log("added", newDoc) }
# });
# list.push('second');
# ```
class @ReactiveList extends ReactiveArray
  constructor: () ->
    # A array of active lineHandlers
    @_definePrivateProperty '_handlers', []

    super

  # ### observer
  # Based on [cursor.observe](http://docs.meteor.com/#observe)
  observe: (callbacks) ->
    handle = new LiveHandler callbacks
    @_handlers.push handle
    @_trigger 'added', @_list[i], i for i in [0...@_list.length] by 1
    handle

  # ### *Mutator methods*
  # ---------------------------------------
  # Optimized mutator methods for reactivity

  # #### pop
  # Removes the last element from an array and returns that element.
  pop: () ->
    rtn = super
    @_trigger 'removed', rtn, @_list.length
    rtn

  # ####
  # Adds one or more elements to the end of an array and returns the new length of the array.
  push: () ->
    orgLength = @_list.length
    rtn = super
    # Fire event, added, addedAt
    @_trigger 'added', @_list[i], i for i in [orgLength...@_list.length] by 1
    rtn

  # #### shift
  # Removes the first element from an array and returns that element.
  shift: () ->
    rtn = super
    @_trigger 'removed', rtn, 0
    rtn

  # #### unshift
  # Adds one or more elements to the front of an array and returns the new length of the array.
  unshift: () ->
    orgLength = @_list.length
    rtn = super
    # Fire event, added, addedAt
    @_trigger 'added', @_list[i], i for i in [0...(@_list.length-orgLength)] by 1
    rtn

  # #### splice
  # Adds and/or removes elements from an array.
  splice: () ->
    orgList = @_list.slice()
    rtn = super

    # start index
    idx = arguments[0]
    idx = orgList.length + idx if idx < 0
    rmAmount = if arguments.length > 1 then arguments[1] else orgList.length - idx
    # Elements where added/changed
    if arguments.length > 2
      addAmount = arguments.length - 2
      if rmAmount > 0
        changedAmount = if rmAmount > addAmount then addAmount else rmAmount
        for i in [0...changedAmount] by 1
          @_trigger 'changed', @_list[idx], orgList[idx], idx
          idx++
        addAmount = addAmount - changedAmount
        rmAmount = rmAmount - changedAmount

      if (rmAmount-addAmount) > 0
        @_trigger 'removed', orgList[idx + i], idx + i for i in [0...rmAmount-addAmount] by 1
      else if (rmAmount-addAmount) < 0
        # only elements where added
        @_trigger 'added', @_list[idx + i], idx + i for i in [0...addAmount-rmAmount] by 1
    else if rmAmount > 0
      @_trigger 'removed', orgList[idx + i], idx + i for i in [0...rmAmount] by 1

    rtn

  # #### reverse
  # Reverses an array in place.  The first array element becomes the last and the last becomes the first.
  reverse: () ->
    super
    array = @_list;
    length = @_list.length
    `for (left = 0, right = length - 1; left < right; left += 1, right -= 1) {
      if (right === left) { continue; }
      this._trigger('movedTo', array[left], right, left);
      this._trigger('movedTo', array[right], left+1, right);
    }`
    return @

  # #### sort
  # Sorts the elements of an array in place and returns the array.
  sort: () ->
    org = @_list.slice()
    super

    return @ if !@_hasActiveTrigger 'movedTo'

    # Create a list of moves that results in @_list
    length = @_list.length
    moves = []
    currentPosition = 0
    while currentPosition < length
      finalPosition = @_list.indexOf(org[currentPosition])

      # A movement of one won't happen
      if currentPosition+1 == finalPosition
        # Look forward maybe we have a group here
        while org[currentPosition+1] == @_list[finalPosition+1]
          finalPosition++
          currentPosition++
        if org[currentPosition] == @_list[finalPosition]
          finalPosition++
          currentPosition++
        finalPosition = @_list.indexOf(org[currentPosition])
      # This is my evil way of detecting duplicates
      if org[currentPosition] == org[currentPosition+1]
        while org[currentPosition-1] == @_list[finalPosition]
          finalPosition++
        if org[currentPosition] == @_list[finalPosition]
          finalPosition++
        finalPosition = @_list.indexOf(org[currentPosition], finalPosition)

      move =
        from: currentPosition
        to: finalPosition
      skip = finalPosition == -1 || lastMove && lastMove.to == move.to && lastMove.from == move.from

      if !skip && finalPosition != currentPosition
        moves.push move
        lastMove = move
        org.splice move.to, 0, (org.splice move.from, 1)[0]

        if finalPosition < currentPosition
          currentPosition = finalPosition
        else
          currentPosition--
      currentPosition++

    for move in moves
      @._trigger 'movedTo', @_list[move.to], move.from, move.to

    return @

  # ### *EJSON Functions*
  # ---------------------------------------
  # These are overrides from [ReactiveArray](reactive-array.html)
  #
  # #### typeName
  # *[EJSON::typeName](http://docs.meteor.com/#ejson_type_typeName)*
  typeName: () ->
    'reactive-list'

  # #### equals
  # *[EJSON::equals](http://docs.meteor.com/#ejson_type_equals)*
  #
  # **obj** object to compare
  equals: (obj) ->
    return obj? &&
      obj instanceof ReactiveList &&
      _.isEqual obj._list, @_list

  # ### *Internal Functions*
  # ---------------------------------------
  #
  # #### _trigger
  # trigger a event to all observeables
  _trigger: (evt) ->
    self = @
    args = _.toArray(arguments).slice(1)
    if evt == 'movedTo'
      trigger = (callbacks) ->
        callbacks[evt].apply  self, args if evt of callbacks
    else
      evtArgs = args.slice(0, -1)
      evtAt = evt + 'At'
      evtAtArgs = args
      trigger = (callbacks) ->
        callbacks[evt].apply  self, evtArgs if evt of callbacks
        callbacks[evtAt].apply self, evtAtArgs if evtAt of callbacks

    for i, handler of @_handlers when i of @_handlers
      if handler.stopped
        delete @_handlers[i]
        continue
      trigger handler.callbacks
    return

  _hasActiveTrigger: (evt) ->
    _.any @_handlers, (handler) ->
      return !handler.stopped && evt of handler.callbacks

  # ### _indexSet
  _indexSet: (idx, val) ->
    rtn = val
    if @_list[idx] != val
      org = list[idx]
      rtn = super
      @_trigger 'changed', @_list[idx], org, idx
    rtn

# ### *Helper methods*
# ---------------------------------------
# #### wrap
# Method for wrapping a array
ReactiveList.wrap = (arr) ->
  obj = new ReactiveList
  obj._list = _.toArray arr
  obj._syncIndexProxies(true)
  obj

# ## EJSON add ReactiveArray
# *[EJSON.addType](https://docs.meteor.com/#ejson_add_type)*
EJSON.addType 'reactive-list', (jsonObj) ->
  ReactiveList.wrap jsonObj

class LiveHandler
  constructor: (callbacks) ->
    self = @
    @stopped = false
    @callbacks = callbacks

    if (Deps.active)
      Deps.onInvalidate () ->
        self.stop()

  stop: () ->
    @stopped = true
