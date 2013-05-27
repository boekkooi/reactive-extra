# # Handlebars each override
HandlebarsEach = Handlebars._default_helpers.each
Handlebars._default_helpers.each = (arg, options) ->
  # Only use our implementation when the arg is a ReactiveList
  return HandlebarsEach.call(this, arg, options) unless arg and arg instanceof ReactiveList

  # Item & else functions (stolen from [templating/deftemplate.js](https://github.com/meteor/meteor/blob/master/packages/templating/deftemplate.js)
  itemFunc = (item) ->
    Spark.labelBranch (item && item._id) || Spark.UNIQUE_LABEL, () ->
      Spark.setDataContext item, Spark.isolate(_.bind(options.fn, null, item))
  elseFunc = () -> if options.inverse then Spark.isolate(options.inverse) else ''

  # Call our curstom observe based SparkArrayList
  SparkListObserve arg, itemFunc, elseFunc

# # Spark listObserve
Spark._ANNOTATION_LIST_OBSERVE = "list_observe";
Spark._ANNOTATION_LIST_OBSERVE_ITEM = "list_observe_item";

# Render a object with a observe function using Spark
# *Most of this code is ripped from [Spark.list](https://github.com/meteor/meteor/blob/master/packages/spark/spark.js#L899)*
SparkListObserve = (observable, itemFunc, elseFunc) ->
  elseFunc = elseFunc || () -> return ''

  # Create a level of indirection around our observable callbacks so we can change them later
  callbacks = {}
  observerCallbacks = {}
  _.each ["addedAt", "changedAt", "removedAt", "movedTo"], (name) ->
    observerCallbacks[name] = ->
      callbacks[name].apply null, arguments

  # Create liverange stubs for the current contents of the observable
  itemArr = []
  _.extend callbacks,
    addedAt: (val, idx) ->
      itemArr[idx] = { liveRange: null, value: val }

  handle = observable.observe observerCallbacks

  # Get the renderer, if any
  renderer = Spark._currentRenderer.get();
  maybeAnnotate = if renderer then _.bind(renderer.annotate, renderer) else (html) -> html

  # Render the initial contents.
  # If we have a renderer, create a range around each item as well as around the list, and save them off for later.
  html = ''
  outerRange = null
  if itemArr.length == 0
    html = elseFunc()
  else
    _.each itemArr, (elt) ->
      html += maybeAnnotate itemFunc(elt.value), Spark._ANNOTATION_LIST_OBSERVE_ITEM, (range) ->
        elt.liveRange = range
        return

  stopped = false
  cleanup = () ->
    handle.stop()
    stopped = true

  html = maybeAnnotate html, Spark._ANNOTATION_LIST_OBSERVE, (range) ->
    if !range
      cleanup()
      return
    outerRange = range
    outerRange.finalize = cleanup
    return

  # No renderer? Then we have no way to update the returned html and we can close the observer.
  if !renderer
    cleanup()
    return html

  notifyParentsRendered = ->
    walk = outerRange
    walk.rendered.call walk.landmark  while (walk = findParentOfType(Spark._ANNOTATION_LANDMARK, walk))
    return

  later = (func) ->
    Deps.afterFlush () ->
      # Spark uses withEventGuard let's just have this won't brake
      func() unless stopped
      return
    return

  # The DOM update callbacks.
  _.extend callbacks,
    addedAt: (val, idx) ->
      later ->
        frag = Spark.render(_.bind(itemFunc, null, val))
        DomUtils.wrapFragmentForContainer frag, outerRange.containerNode()
        range = makeRange(Spark._ANNOTATION_LIST_ITEM, frag)
        if itemArr.length == 0
          Spark.finalize outerRange.replaceContents(frag)
        else
          itemArr[idx-1].liveRange.insertAfter frag
        itemArr[idx] = { liveRange: range, value: val }

    removedAt: (val, idx) ->
      later ->
        if itemArr.length == 1
          frag = Spark.render(elseFunc)
          DomUtils.wrapFragmentForContainer frag, outerRange.containerNode()
          Spark.finalize outerRange.replaceContents(frag)
        else
          Spark.finalize itemArr[idx].liveRange.extract()
        itemArr.splice idx, 1
        notifyParentsRendered()

    movedTo: (val, fromIdx, toIdx) ->
      later ->
        elt = (itemArr.splice fromIdx, 1)[0]
        frag = elt.liveRange.extract()
        if toIdx of itemArr
          itemArr[toIdx].liveRange.insertBefore frag
        else
          itemArr[toIdx-1].liveRange.insertAfter frag
        itemArr.splice toIdx, 0, elt
        notifyParentsRendered()

    changedAt: (val, idx) ->
      later ->
        elt = itemArr[idx]
        throw new Error("Unknown item at index: " + idx)  unless elt
        elt.value = val
        Spark.renderToRange elt.liveRange, _.bind(itemFunc, null, elt.value)

  return html

# ## findParentOfType
# Ripped from [Spark.list](https://github.com/meteor/meteor/blob/master/packages/spark/spark.js#L77)*
findParentOfType = (type, range) ->
  loop
    range = range.findParent()
    break unless range and range.type isnt type
  range

# ## makeRange
# Ripped from [Spark.list](https://github.com/meteor/meteor/blob/master/packages/spark/spark.js#L63)*
makeRange = (type, start, end, inner) ->
  range = new LiveRange(Spark._TAG, start, end, inner)
  range.type = type
  range