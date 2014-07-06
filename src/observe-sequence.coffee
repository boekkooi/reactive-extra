# Extending ObserveSequence (https://github.com/meteor/meteor/blob/devel/packages/observe-sequence/)
ObserveSequence = Package['observe-sequence'].ObserveSequence

idStringify = LocalCollection._idStringify;
idParse = LocalCollection._idParse;

# Allow ReactiveList
ObserveSequenceFetch = ObserveSequence.fetch
ObserveSequence.fetch = (seq) ->
  # Only use our implementation when the seq is a ReactiveList
  return seq if seq and seq instanceof ReactiveList

  return ObserveSequenceFetch.call(@, seq)

# Add observe support for ReactiveList
ObserveSequenceObserve = ObserveSequence.observe
ObserveSequence.observe = (sequenceFunc, callbacks) ->
  # First we need to check if we should handle the sequence since there is nicer way to extend this.
  observe = false
  Deps.nonreactive () ->
    observe = sequenceFunc() instanceof ReactiveList

  # Not a ReactiveList (aka not my problem)
  return ObserveSequenceObserve.call(@, sequenceFunc, callbacks) unless observe

  # Mostly a copy from observe_sequence.js
  lastSeq = null
  lastSeqArray = []
  computation = Deps.autorun () ->
    seq = sequenceFunc()

    if activeObserveHandle
      lastSeqArray = _.map activeObserveHandle._fetch(), (doc) ->
        {_id: doc._id, item: doc}

      activeObserveHandle.stop()
      activeObserveHandle = null

    # create id's for the list
    idsUsed = {};
    seqArray = _.map seq, (item, index) ->
      id = undefined
      if typeof item is "string"
        # ensure not empty, since other layers (eg DomRange) assume this as well
        id = "-" + item
      else if typeof item is "number" or typeof item is "boolean" or item is `undefined`
        id = item
      else if typeof item is "object"
        id = (item and item._id) or index
      else
        throw new Error("{{#each}} doesn't support arrays with " + "elements of type " + typeof item)

      idString = idStringify(id)
      if idsUsed[idString]
        warn "duplicate id " + id + " in", seq  if typeof item is "object" and "_id" of item
        id = Random.id()
      else
        idsUsed[idString] = true
      return {
        _id: id
        item: item
      }
    diffArray lastSeqArray, seqArray, callbacks

    lastSeq = seq
    lastSeqArray = seqArray

  return {
    stop: () ->
      computation.stop()
      return
  }

# Direct copy of diffArray in observe_sequence.js
diffArray = (lastSeqArray, seqArray, callbacks) ->
  diffFn = Package.minimongo.LocalCollection._diffQueryOrderedChanges
  oldIdObjects = []
  newIdObjects = []
  posOld = {}
  posNew = {}
  posCur = {}
  lengthCur = lastSeqArray.length
  _.each seqArray, (doc, i) ->
    newIdObjects.push _id: doc._id
    posNew[idStringify(doc._id)] = i
    return

  _.each lastSeqArray, (doc, i) ->
    oldIdObjects.push _id: doc._id
    posOld[idStringify(doc._id)] = i
    posCur[idStringify(doc._id)] = i
    return

  diffFn oldIdObjects, newIdObjects,
    addedBefore: (id, doc, before) ->
      position = (if before then posCur[idStringify(before)] else lengthCur)
      _.each posCur, (pos, id) ->
        posCur[id]++  if pos >= position
        return

      lengthCur++
      posCur[idStringify(id)] = position
      callbacks.addedAt id, seqArray[posNew[idStringify(id)]].item, position, before
      return

    movedBefore: (id, before) ->
      prevPosition = posCur[idStringify(id)]
      position = (if before then posCur[idStringify(before)] else lengthCur - 1)
      _.each posCur, (pos, id) ->
        if pos >= prevPosition and pos <= position
          posCur[id]--
        else posCur[id]++  if pos <= prevPosition and pos >= position
        return

      posCur[idStringify(id)] = position
      callbacks.movedTo id, seqArray[posNew[idStringify(id)]].item, prevPosition, position, before
      return

    removed: (id) ->
      prevPosition = posCur[idStringify(id)]
      _.each posCur, (pos, id) ->
        posCur[id]--  if pos >= prevPosition
        return

      delete posCur[idStringify(id)]

      lengthCur--
      callbacks.removedAt id, lastSeqArray[posOld[idStringify(id)]].item, prevPosition
      return

  _.each posNew, (pos, idString) ->
    id = idParse(idString)
    if _.has(posOld, idString)
      newItem = seqArray[pos].item
      oldItem = lastSeqArray[posOld[idString]].item
      callbacks.changedAt id, newItem, oldItem, pos  if typeof newItem is "object" or newItem isnt oldItem
    return
  return