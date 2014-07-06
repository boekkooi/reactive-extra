// Generated by CoffeeScript 1.7.1
(function() {
  var ObserveSequence, ObserveSequenceFetch, ObserveSequenceObserve, diffArray, idParse, idStringify;

  ObserveSequence = Package['observe-sequence'].ObserveSequence;

  idStringify = LocalCollection._idStringify;

  idParse = LocalCollection._idParse;

  ObserveSequenceFetch = ObserveSequence.fetch;

  ObserveSequence.fetch = function(seq) {
    if (seq && seq instanceof ReactiveList) {
      return seq;
    }
    return ObserveSequenceFetch.call(this, seq);
  };

  ObserveSequenceObserve = ObserveSequence.observe;

  ObserveSequence.observe = function(sequenceFunc, callbacks) {
    var computation, lastSeq, lastSeqArray, observe;
    observe = false;
    Deps.nonreactive(function() {
      return observe = sequenceFunc() instanceof ReactiveList;
    });
    if (!observe) {
      return ObserveSequenceObserve.call(this, sequenceFunc, callbacks);
    }
    lastSeq = null;
    lastSeqArray = [];
    computation = Deps.autorun(function() {
      var activeObserveHandle, idsUsed, seq, seqArray;
      seq = sequenceFunc();
      if (activeObserveHandle) {
        lastSeqArray = _.map(activeObserveHandle._fetch(), function(doc) {
          return {
            _id: doc._id,
            item: doc
          };
        });
        activeObserveHandle.stop();
        activeObserveHandle = null;
      }
      idsUsed = {};
      seqArray = _.map(seq, function(item, index) {
        var id, idString;
        id = void 0;
        if (typeof item === "string") {
          id = "-" + item;
        } else if (typeof item === "number" || typeof item === "boolean" || item === undefined) {
          id = item;
        } else if (typeof item === "object") {
          id = (item && item._id) || index;
        } else {
          throw new Error("{{#each}} doesn't support arrays with " + "elements of type " + typeof item);
        }
        idString = idStringify(id);
        if (idsUsed[idString]) {
          if (typeof item === "object" && "_id" in item) {
            warn("duplicate id " + id + " in", seq);
          }
          id = Random.id();
        } else {
          idsUsed[idString] = true;
        }
        return {
          _id: id,
          item: item
        };
      });
      diffArray(lastSeqArray, seqArray, callbacks);
      lastSeq = seq;
      return lastSeqArray = seqArray;
    });
    return {
      stop: function() {
        computation.stop();
      }
    };
  };

  diffArray = function(lastSeqArray, seqArray, callbacks) {
    var diffFn, lengthCur, newIdObjects, oldIdObjects, posCur, posNew, posOld;
    diffFn = Package.minimongo.LocalCollection._diffQueryOrderedChanges;
    oldIdObjects = [];
    newIdObjects = [];
    posOld = {};
    posNew = {};
    posCur = {};
    lengthCur = lastSeqArray.length;
    _.each(seqArray, function(doc, i) {
      newIdObjects.push({
        _id: doc._id
      });
      posNew[idStringify(doc._id)] = i;
    });
    _.each(lastSeqArray, function(doc, i) {
      oldIdObjects.push({
        _id: doc._id
      });
      posOld[idStringify(doc._id)] = i;
      posCur[idStringify(doc._id)] = i;
    });
    diffFn(oldIdObjects, newIdObjects, {
      addedBefore: function(id, doc, before) {
        var position;
        position = (before ? posCur[idStringify(before)] : lengthCur);
        _.each(posCur, function(pos, id) {
          if (pos >= position) {
            posCur[id]++;
          }
        });
        lengthCur++;
        posCur[idStringify(id)] = position;
        callbacks.addedAt(id, seqArray[posNew[idStringify(id)]].item, position, before);
      },
      movedBefore: function(id, before) {
        var position, prevPosition;
        prevPosition = posCur[idStringify(id)];
        position = (before ? posCur[idStringify(before)] : lengthCur - 1);
        _.each(posCur, function(pos, id) {
          if (pos >= prevPosition && pos <= position) {
            posCur[id]--;
          } else {
            if (pos <= prevPosition && pos >= position) {
              posCur[id]++;
            }
          }
        });
        posCur[idStringify(id)] = position;
        callbacks.movedTo(id, seqArray[posNew[idStringify(id)]].item, prevPosition, position, before);
      },
      removed: function(id) {
        var prevPosition;
        prevPosition = posCur[idStringify(id)];
        _.each(posCur, function(pos, id) {
          if (pos >= prevPosition) {
            posCur[id]--;
          }
        });
        delete posCur[idStringify(id)];
        lengthCur--;
        callbacks.removedAt(id, lastSeqArray[posOld[idStringify(id)]].item, prevPosition);
      }
    });
    _.each(posNew, function(pos, idString) {
      var id, newItem, oldItem;
      id = idParse(idString);
      if (_.has(posOld, idString)) {
        newItem = seqArray[pos].item;
        oldItem = lastSeqArray[posOld[idString]].item;
        if (typeof newItem === "object" || newItem !== oldItem) {
          callbacks.changedAt(id, newItem, oldItem, pos);
        }
      }
    });
  };

}).call(this);