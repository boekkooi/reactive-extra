// Generated by CoffeeScript 1.7.1
(function() {
  var LiveHandler,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.ReactiveList = (function(_super) {
    __extends(ReactiveList, _super);

    function ReactiveList() {
      this._definePrivateProperty('_handlers', []);
      ReactiveList.__super__.constructor.apply(this, arguments);
    }

    ReactiveList.prototype.observe = function(callbacks) {
      var handle, i, _i, _ref;
      handle = new LiveHandler(callbacks);
      this._handlers.push(handle);
      for (i = _i = 0, _ref = this._list.length; _i < _ref; i = _i += 1) {
        this._trigger('added', this._list[i], i);
      }
      return handle;
    };

    ReactiveList.prototype.pop = function() {
      var rtn;
      rtn = ReactiveList.__super__.pop.apply(this, arguments);
      this._trigger('removed', rtn, this._list.length);
      return rtn;
    };

    ReactiveList.prototype.push = function() {
      var i, orgLength, rtn, _i, _ref;
      orgLength = this._list.length;
      rtn = ReactiveList.__super__.push.apply(this, arguments);
      for (i = _i = orgLength, _ref = this._list.length; _i < _ref; i = _i += 1) {
        this._trigger('added', this._list[i], i);
      }
      return rtn;
    };

    ReactiveList.prototype.shift = function() {
      var rtn;
      rtn = ReactiveList.__super__.shift.apply(this, arguments);
      this._trigger('removed', rtn, 0);
      return rtn;
    };

    ReactiveList.prototype.unshift = function() {
      var i, orgLength, rtn, _i, _ref;
      orgLength = this._list.length;
      rtn = ReactiveList.__super__.unshift.apply(this, arguments);
      for (i = _i = 0, _ref = this._list.length - orgLength; _i < _ref; i = _i += 1) {
        this._trigger('added', this._list[i], i);
      }
      return rtn;
    };

    ReactiveList.prototype.splice = function() {
      var addAmount, changedAmount, i, idx, orgList, rmAmount, rtn, _i, _j, _k, _l, _ref, _ref1;
      orgList = this._list.slice();
      rtn = ReactiveList.__super__.splice.apply(this, arguments);
      idx = arguments[0];
      if (idx < 0) {
        idx = orgList.length + idx;
      }
      rmAmount = arguments.length > 1 ? arguments[1] : orgList.length - idx;
      if (arguments.length > 2) {
        addAmount = arguments.length - 2;
        if (rmAmount > 0) {
          changedAmount = rmAmount > addAmount ? addAmount : rmAmount;
          for (i = _i = 0; _i < changedAmount; i = _i += 1) {
            this._trigger('changed', this._list[idx], orgList[idx], idx);
            idx++;
          }
          addAmount = addAmount - changedAmount;
          rmAmount = rmAmount - changedAmount;
        }
        if ((rmAmount - addAmount) > 0) {
          for (i = _j = 0, _ref = rmAmount - addAmount; _j < _ref; i = _j += 1) {
            this._trigger('removed', orgList[idx + i], idx + i);
          }
        } else if ((rmAmount - addAmount) < 0) {
          for (i = _k = 0, _ref1 = addAmount - rmAmount; _k < _ref1; i = _k += 1) {
            this._trigger('added', this._list[idx + i], idx + i);
          }
        }
      } else if (rmAmount > 0) {
        for (i = _l = 0; _l < rmAmount; i = _l += 1) {
          this._trigger('removed', orgList[idx + i], idx + i);
        }
      }
      return rtn;
    };

    ReactiveList.prototype.reverse = function() {
      var array, length;
      ReactiveList.__super__.reverse.apply(this, arguments);
      array = this._list;
      length = this._list.length;
      for (left = 0, right = length - 1; left < right; left += 1, right -= 1) {
      if (right === left) { continue; }
      this._trigger('movedTo', array[left], right, left);
      this._trigger('movedTo', array[right], left+1, right);
    };
      return this;
    };

    ReactiveList.prototype.sort = function() {
      var currentPosition, finalPosition, lastMove, length, move, moves, org, skip, _i, _len;
      org = this._list.slice();
      ReactiveList.__super__.sort.apply(this, arguments);
      if (!this._hasActiveTrigger('movedTo')) {
        return this;
      }
      length = this._list.length;
      moves = [];
      currentPosition = 0;
      while (currentPosition < length) {
        finalPosition = this._list.indexOf(org[currentPosition]);
        if (currentPosition + 1 === finalPosition) {
          while (org[currentPosition + 1] === this._list[finalPosition + 1]) {
            finalPosition++;
            currentPosition++;
          }
          if (org[currentPosition] === this._list[finalPosition]) {
            finalPosition++;
            currentPosition++;
          }
          finalPosition = this._list.indexOf(org[currentPosition]);
        }
        if (org[currentPosition] === org[currentPosition + 1]) {
          while (org[currentPosition - 1] === this._list[finalPosition]) {
            finalPosition++;
          }
          if (org[currentPosition] === this._list[finalPosition]) {
            finalPosition++;
          }
          finalPosition = this._list.indexOf(org[currentPosition], finalPosition);
        }
        move = {
          from: currentPosition,
          to: finalPosition
        };
        skip = finalPosition === -1 || lastMove && lastMove.to === move.to && lastMove.from === move.from;
        if (!skip && finalPosition !== currentPosition) {
          moves.push(move);
          lastMove = move;
          org.splice(move.to, 0, (org.splice(move.from, 1))[0]);
          if (finalPosition < currentPosition) {
            currentPosition = finalPosition;
          } else {
            currentPosition--;
          }
        }
        currentPosition++;
      }
      for (_i = 0, _len = moves.length; _i < _len; _i++) {
        move = moves[_i];
        this._trigger('movedTo', this._list[move.to], move.from, move.to);
      }
      return this;
    };

    ReactiveList.prototype.typeName = function() {
      return 'reactive-list';
    };

    ReactiveList.prototype.equals = function(obj) {
      return (obj != null) && obj instanceof ReactiveList && _.isEqual(obj._list, this._list);
    };

    ReactiveList.prototype._trigger = function(evt) {
      var args, evtArgs, evtAt, evtAtArgs, handler, i, self, trigger, _ref;
      self = this;
      args = _.toArray(arguments).slice(1);
      if (evt === 'movedTo') {
        trigger = function(callbacks) {
          if (evt in callbacks) {
            return callbacks[evt].apply(self, args);
          }
        };
      } else {
        evtArgs = args.slice(0, -1);
        evtAt = evt + 'At';
        evtAtArgs = args;
        trigger = function(callbacks) {
          if (evt in callbacks) {
            callbacks[evt].apply(self, evtArgs);
          }
          if (evtAt in callbacks) {
            return callbacks[evtAt].apply(self, evtAtArgs);
          }
        };
      }
      _ref = this._handlers;
      for (i in _ref) {
        handler = _ref[i];
        if (!(i in this._handlers)) {
          continue;
        }
        if (handler.stopped) {
          delete this._handlers[i];
          continue;
        }
        trigger(handler.callbacks);
      }
    };

    ReactiveList.prototype._hasActiveTrigger = function(evt) {
      return _.any(this._handlers, function(handler) {
        return !handler.stopped && evt in handler.callbacks;
      });
    };

    ReactiveList.prototype._indexSet = function(idx, val) {
      var org, rtn;
      rtn = val;
      if (this._list[idx] !== val) {
        org = list[idx];
        rtn = ReactiveList.__super__._indexSet.apply(this, arguments);
        this._trigger('changed', this._list[idx], org, idx);
      }
      return rtn;
    };

    return ReactiveList;

  })(ReactiveArray);

  ReactiveList.wrap = function(arr) {
    var obj;
    obj = new ReactiveList;
    obj._list = _.toArray(arr);
    obj._syncIndexProxies(true);
    return obj;
  };

  EJSON.addType('reactive-list', function(jsonObj) {
    return ReactiveList.wrap(jsonObj);
  });

  LiveHandler = (function() {
    function LiveHandler(callbacks) {
      var self;
      self = this;
      this.stopped = false;
      this.callbacks = callbacks;
      if (Deps.active) {
        Deps.onInvalidate(function() {
          return self.stop();
        });
      }
    }

    LiveHandler.prototype.stop = function() {
      return this.stopped = true;
    };

    return LiveHandler;

  })();

}).call(this);
