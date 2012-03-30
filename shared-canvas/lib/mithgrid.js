
/*
# mithgrid JavaScript Library v0.0.1
#
# Date: Wed Jan 18 11:51:47 2012 -0500
#
# (c) Copyright University of Maryland 2011-2012.  All rights reserved.
#
# (c) Copyright Texas A&M University 2010.  All rights reserved.
#
# Portions of this code are copied from The SIMILE Project:
#  (c) Copyright The SIMILE Project 2006. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

(function() {
  var MITHGrid, jQuery, _ref, _ref2,
    __slice = Array.prototype.slice,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  MITHGrid = (_ref = this.MITHGrid) != null ? _ref : this.MITHGrid = {};

  jQuery = (_ref2 = this.jQuery) != null ? _ref2 : this.jQuery = {};

  (function($, MITHGrid) {
    var MITHGridDefaults, genericNamespacer, initViewCounter, _ref3;
    if ((typeof window !== "undefined" && window !== null ? (_ref3 = window.console) != null ? _ref3.log : void 0 : void 0) != null) {
      MITHGrid.debug = window.console.log;
    } else {
      MITHGrid.debug = function() {};
    }
    MITHGrid.error = function() {
      MITHGrid.debug.call({}, arguments);
      return {
        'arguments': arguments
      };
    };
    MITHGrid.namespace = function(nom, fn) {
      return genericNamespacer(MITHGrid, nom, fn);
    };
    genericNamespacer = function(base, nom, fn) {
      var bits, newbase;
      bits = nom.split('.');
      while (bits.length > 1) {
        if (!base[bits[0]]) {
          base = genericNamespacer(base, bits[0]);
          bits.shift();
        }
      }
      if (!(base[bits[0]] != null)) {
        newbase = {
          namespace: function(nom2, fn2) {
            return genericNamespacer(newbase, nom2, fn2);
          },
          debug: MITHGrid.debug
        };
      }
      base[bits[0]] = newbase;
      if (fn != null) fn(base[bits[0]]);
      return base[bits[0]];
    };
    MITHGrid.globalNamespace = function(nom, fn) {
      var globals, _base, _base2;
      globals = window;
      globals[nom] || (globals[nom] = {});
      (_base = globals[nom])["debug"] || (_base["debug"] = MITHGrid.debug);
      (_base2 = globals[nom])["namespace"] || (_base2["namespace"] = function(n, f) {
        return genericNamespacer(globals[nom], n, f);
      });
      if (fn != null) fn(globals[nom]);
      return globals[nom];
    };
    MITHGrid.normalizeArgs = function(type, types, container, options) {
      if (!(options != null) && $.isPlainObject(container)) {
        options = container;
        container = void 0;
      }
      if (!(container != null)) {
        if (typeof types !== "string") {
          if (!$.isArray(types)) {
            container = types;
            types = [];
          }
        }
      }
      if (!(options != null)) {
        if (typeof types === "string") {
          types = [types, type];
          options = {};
        } else if ($.isArray(types)) {
          types.push(type);
          options = {};
        } else {
          options = types;
          types = type;
        }
      } else {
        if (typeof types === "string") {
          types = [types, type];
        } else if ($.isArray(types)) {
          types.push(type);
        } else {
          types = type;
        }
      }
      return [types, container, options];
    };
    MITHGridDefaults = {};
    MITHGrid.defaults = function(namespace, defaults) {
      MITHGridDefaults[namespace] || (MITHGridDefaults[namespace] = {});
      return MITHGridDefaults[namespace] = $.extend(true, MITHGridDefaults[namespace], defaults);
    };
    MITHGrid.initSynchronizer = function(callbacks) {
      var counter, done, fired, that;
      that = {};
      counter = 1;
      done = false;
      fired = false;
      if (!(callbacks.done != null)) {
        that.increment = function() {};
        that.decrement = that.increment;
        that.done = that.increment;
        that.add = function(v) {};
      } else {
        that.increment = function() {
          return counter += 1;
        };
        that.add = function(n) {
          return counter += n;
        };
        that.decrement = function() {
          counter -= 1;
          if (counter <= 0 && done && !fired) {
            setTimeout(callbacks.done, 0);
            fired = true;
          }
          return counter;
        };
        that.done = function() {
          done = true;
          return that.decrement();
        };
      }
      return that;
    };
    MITHGrid.initEventFirer = function(isPreventable, isUnicast) {
      var listeners, that;
      that = {};
      that.isPreventable = isPreventable;
      that.isUnicast = isUnicast;
      listeners = [];
      that.addListener = function(listener, namespace) {
        return listeners.push([listener, namespace]);
      };
      that.removeListener = function(listener) {
        var l;
        if (typeof listener === "string") {
          return listeners = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = listeners.length; _i < _len; _i++) {
              l = listeners[_i];
              if (l[1] !== listener) _results.push(l);
            }
            return _results;
          })();
        } else {
          return listeners = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = listeners.length; _i < _len; _i++) {
              l = listeners[_i];
              if (l[0] !== listener) _results.push(l);
            }
            return _results;
          })();
        }
      };
      if (isUnicast) {
        that.fire = function() {
          var args, _ref4;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (listeners.length > 0) {
            try {
              return (_ref4 = listeners[0])[0].apply(_ref4, args);
            } catch (e) {
              return console.log(e);
            }
          } else {
            return true;
          }
        };
      } else if (isPreventable) {
        that.fire = function() {
          var args, l, listener, r, _i, _len;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          r = true;
          for (_i = 0, _len = listeners.length; _i < _len; _i++) {
            listener = listeners[_i];
            l = listener[0];
            try {
              r = l.apply(null, args);
            } catch (e) {
              console.log(e);
            }
            if (r === false) return false;
          }
          return true;
        };
      } else {
        that.fire = function() {
          var args, listener, _i, _len;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          for (_i = 0, _len = listeners.length; _i < _len; _i++) {
            listener = listeners[_i];
            try {
              listener[0].apply(listener, args);
            } catch (e) {
              console.log(listener[0], args, e);
            }
          }
          return true;
        };
      }
      return that;
    };
    initViewCounter = 0;
    MITHGrid.initInstance = function(namespace, container, config) {
      var bits, c, k, ns, options, that, _i, _len, _ref4;
      if (!(config != null)) {
        config = container;
        container = void 0;
      }
      if (!(config != null) && !(typeof namespace === "string" || $.isArray(namespace))) {
        config = namespace;
        namespace = null;
      }
      that = {};
      options = {};
      if (namespace != null) {
        if (typeof namespace === "string") namespace = [namespace];
        namespace.reverse();
        for (_i = 0, _len = namespace.length; _i < _len; _i++) {
          ns = namespace[_i];
          bits = ns.split('.');
          ns = bits.shift();
          options = $.extend(true, {}, MITHGridDefaults[ns] || {});
          while (bits.length > 0) {
            ns = ns + "." + bits.shift();
            options = $.extend(true, options, MITHGridDefaults[ns] || {});
          }
        }
      }
      options = $.extend(true, options, config || {});
      initViewCounter += 1;
      that.id = initViewCounter;
      that.options = options;
      that.container = container;
      that.events = {};
      if (that.options.events != null) {
        _ref4 = that.options.events;
        for (k in _ref4) {
          c = _ref4[k];
          if (c != null) {
            if (typeof c === "string") c = [c];
          } else {
            c = [];
          }
          that.events[k] = MITHGrid.initEventFirer((__indexOf.call(c, "preventable") >= 0), (__indexOf.call(c, "unicast") >= 0));
        }
      }
      return that;
    };
    MITHGrid.namespace('Data', function(Data) {
      Data.namespace('Set', function(Set) {
        return Set.initInstance = function(values) {
          var count, i, items, items_list, recalc_items, that, _i, _len;
          that = {};
          items = {};
          count = 0;
          recalc_items = true;
          items_list = [];
          that.isSet = true;
          that.items = function() {
            var i;
            if (recalc_items) {
              items_list = [];
              for (i in items) {
                if (typeof i === "string" && items[i] === true) items_list.push(i);
              }
            }
            return items_list;
          };
          that.add = function(item) {
            if (!(items[item] != null)) {
              items[item] = true;
              recalc_items = true;
              return count += 1;
            }
          };
          that.remove = function(item) {
            if (items[item] != null) {
              delete items[item];
              recalc_items = true;
              return count -= 1;
            }
          };
          that.empty = function() {
            items = {};
            count = 0;
            recalc_items = false;
            items_list = [];
            return;
          };
          that.visit = function(fn) {
            var o, _results;
            _results = [];
            for (o in items) {
              if (fn(o) === true) {
                break;
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          };
          that.contains = function(o) {
            return items[o] != null;
          };
          that.size = function() {
            if (recalc_items) {
              return that.items().length;
            } else {
              return items_list.length;
            }
          };
          if (values instanceof Array) {
            for (_i = 0, _len = values.length; _i < _len; _i++) {
              i = values[_i];
              that.add(i);
            }
          }
          return that;
        };
      });
      Data.namespace('Type', function(Type) {
        return Type.initInstance = function(t) {
          var that;
          return that = {
            name: t,
            custom: {}
          };
        };
      });
      Data.namespace('Property', function(Property) {
        return Property.initInstance = function(p) {
          var that;
          return that = {
            name: p,
            getValueType: function() {
              var _ref4;
              return (_ref4 = that.valueType) != null ? _ref4 : 'text';
            }
          };
        };
      });
      Data.namespace('Store', function(Store) {
        return Store.initInstance = function(options) {
          var getUnion, indexFillSet, indexPut, ops, properties, quiesc_events, set, spo, that, types;
          quiesc_events = false;
          set = Data.initSet();
          types = {};
          properties = {};
          spo = {};
          ops = {};
          if (options == null) options = {};
          that = MITHGrid.initInstance("MITHGrid.Data.Store", options);
          that.items = set.items;
          that.contains = set.contains;
          that.visit = set.visit;
          that.size = set.size;
          indexPut = function(index, x, y, z) {
            var array, counts, hash;
            hash = index[x];
            if (!(hash != null)) {
              hash = {
                values: {},
                counts: {}
              };
              index[x] = hash;
            }
            array = hash.values[y];
            counts = hash.counts[y];
            if (!(array != null)) {
              array = [];
              hash.values[y] = array;
            }
            if (!(counts != null)) {
              counts = {};
              hash.counts[y] = counts;
            } else if (__indexOf.call(array, z) >= 0) {
              counts[z] += 1;
              return;
            }
            array.push(z);
            return counts[z] = 1;
          };
          indexFillSet = function(index, x, y, set, filter) {
            var array, hash, z, _i, _j, _len, _len2, _results, _results2;
            hash = index[x];
            if (hash != null) {
              array = hash.values[y];
              if (array != null) {
                if (filter != null) {
                  _results = [];
                  for (_i = 0, _len = array.length; _i < _len; _i++) {
                    z = array[_i];
                    if (filter.contains(z)) {
                      _results.push(set.add(z));
                    } else {
                      _results.push(void 0);
                    }
                  }
                  return _results;
                } else {
                  _results2 = [];
                  for (_j = 0, _len2 = array.length; _j < _len2; _j++) {
                    z = array[_j];
                    _results2.push(set.add(z));
                  }
                  return _results2;
                }
              }
            }
          };
          getUnion = function(index, xSet, y, set, filter) {
            if (!(set != null)) set = Data.initSet();
            xSet.visit(function(x) {
              return indexFillSet(index, x, y, set, filter);
            });
            return set;
          };
          that.addProperty = function(nom, options) {
            var prop;
            prop = Data.initProperty(nom);
            if ((options != null ? options.valueType : void 0) != null) {
              prop.valueType = options.valueType;
              properties[nom] = prop;
            }
            return prop;
          };
          that.getProperty = function(nom) {
            var _ref4;
            return (_ref4 = properties[nom]) != null ? _ref4 : Data.initProperty(nom);
          };
          that.addType = function(nom, options) {
            var type;
            type = Data.initType(nom);
            types[nom] = type;
            return type;
          };
          that.getType = function(nom) {
            var _ref4;
            return (_ref4 = types[nom]) != null ? _ref4 : Data.initType(nom);
          };
          that.getItem = function(id) {
            var _ref4, _ref5;
            return (_ref4 = (_ref5 = spo[id]) != null ? _ref5.values : void 0) != null ? _ref4 : {};
          };
          that.getItems = function(ids) {
            if (!$.isArray(ids)) return [that.getItem(ids)];
            return $.map(ids, function(id, idx) {
              return that.getItem(id);
            });
          };
          that.removeItems = function(ids, fn) {
            var id, id_list, indexRemove, indexRemoveFn, removeItem, removeValues, _i, _len;
            id_list = [];
            indexRemove = function(index, x, y, z) {
              var array, counts, hash, i, k, sum, v;
              hash = index[x];
              if (!(hash != null)) return;
              array = hash.values[y];
              counts = hash.counts[y];
              if (!(array != null) || !(counts != null)) return;
              counts[z] -= 1;
              if (counts[z] < 1) {
                i = $.inArray(z, array);
                if (i === 0) {
                  array = array.slice(1, array.length);
                } else if (i === array.length - 1) {
                  array = array.slice(0, i);
                } else if (i > 0) {
                  array = array.slice(0, i).concat(array.slice(i + 1, array.length));
                }
                if (array.length > 0) {
                  hash.values[y] = array;
                } else {
                  delete hash.values[y];
                }
                delete counts[z];
                sum = 0;
                for (k in counts) {
                  v = counts[k];
                  sum += v;
                }
                if (sum === 0) return delete index[x];
              }
            };
            indexRemoveFn = function(s, p, o) {
              indexRemove(spo, s, p, o);
              return indexRemove(ops, o, p, s);
            };
            removeValues = function(id, p, list) {
              var o, _i, _len, _results;
              _results = [];
              for (_i = 0, _len = list.length; _i < _len; _i++) {
                o = list[_i];
                _results.push(indexRemoveFn(id, p, o));
              }
              return _results;
            };
            removeItem = function(id) {
              var entry, items, p, type;
              entry = that.getItem(id);
              type = entry.type;
              if ($.isArray(type)) type = type[0];
              for (p in entry) {
                items = entry[p];
                if (typeof p !== "string" || (p === "id" || p === "type")) {
                  continue;
                }
                removeValues(id, p, items);
              }
              return removeValues(id, 'type', [type]);
            };
            for (_i = 0, _len = ids.length; _i < _len; _i++) {
              id = ids[_i];
              removeItem(id);
              id_list.push(id);
              set.remove(id);
            }
            that.events.onModelChange.fire(that, id_list);
            if (fn != null) return fn();
          };
          that.updateItems = function(items, fn) {
            var chunk_size, f, id_list, indexPutFn, indexRemove, indexRemoveFn, n, updateItem;
            id_list = [];
            indexRemove = function(index, x, y, z) {
              var array, counts, hash, i;
              hash = index[x];
              if (!(hash != null)) return;
              array = hash.values[y];
              counts = hash.counts[y];
              if (!(array != null) || !(counts != null)) return;
              counts[z] -= 1;
              if (counts[z] < 1) {
                i = $.inArray(z, array);
                if (i === 0) {
                  array = array.slice(1, array.length);
                } else if (i === array.length - 1) {
                  array = array.slice(0, i);
                } else if (i > 0) {
                  array = array.slice(0, i).concat(array.slice(i + 1, array.length));
                }
                if (array.length > 0) {
                  hash.values[y] = array;
                } else {
                  delete hash.values[y];
                }
                return delete counts[z];
              }
            };
            indexPutFn = function(s, p, o) {
              indexPut(spo, s, p, o);
              return indexPut(ops, o, p, s);
            };
            indexRemoveFn = function(s, p, o) {
              indexRemove(spo, s, p, o);
              return indexRemove(ops, o, p, s);
            };
            updateItem = function(entry) {
              var changed, id, itemListIdentical, items, old_item, p, putValues, removeValues, s, type;
              id = entry.id;
              type = entry.type;
              changed = false;
              itemListIdentical = function(to, from) {
                var i, items_same, _ref4;
                items_same = true;
                if (to.length !== from.length) return false;
                for (i = 0, _ref4 = to.length; 0 <= _ref4 ? i < _ref4 : i > _ref4; 0 <= _ref4 ? i++ : i--) {
                  if (to[i] !== from[i]) items_same = false;
                }
                return items_same;
              };
              removeValues = function(id, p, list) {
                var o, _i, _len, _results;
                _results = [];
                for (_i = 0, _len = list.length; _i < _len; _i++) {
                  o = list[_i];
                  _results.push(indexRemoveFn(id, p, o));
                }
                return _results;
              };
              putValues = function(id, p, list) {
                var o, _i, _len, _results;
                _results = [];
                for (_i = 0, _len = list.length; _i < _len; _i++) {
                  o = list[_i];
                  _results.push(indexPutFn(id, p, o));
                }
                return _results;
              };
              if ($.isArray(id)) id = id[0];
              if ($.isArray(type)) type = type[0];
              old_item = that.getItem(id);
              for (p in entry) {
                items = entry[p];
                if (typeof p !== "string" || (p === "id" || p === "type")) {
                  continue;
                }
                if (!$.isArray(items)) items = [items];
                s = items.length;
                if (!(old_item[p] != null)) {
                  putValues(id, p, items);
                  changed = true;
                } else if (!itemListIdentical(items, old_item[p])) {
                  changed = true;
                  removeValues(id, p, old_item[p]);
                  putValues(id, p, items);
                }
              }
              return changed;
            };
            that.events.onBeforeUpdating.fire(that);
            n = items.length;
            chunk_size = parseInt(n / 100, 10);
            if (chunk_size > 200) chunk_size = 200;
            if (chunk_size < 1) chunk_size = 1;
            f = function(start) {
              var end, entry, i;
              end = start + chunk_size;
              if (end > n) end = n;
              for (i = start; start <= end ? i < end : i > end; start <= end ? i++ : i--) {
                entry = items[i];
                if (typeof entry === "object" && updateItem(entry)) {
                  id_list.push(entry.id);
                }
              }
              if (end < n) {
                return setTimeout(function() {
                  return f(end);
                }, 0);
              } else {
                that.events.onAfterUpdating.fire(that);
                that.events.onModelChange.fire(that, id_list);
                if (fn != null) return fn();
              }
            };
            return f(0);
          };
          that.loadItems = function(items, endFn) {
            var chunk_size, f, id_list, indexFn, loadItem, n;
            id_list = [];
            indexFn = function(s, p, o) {
              indexPut(spo, s, p, o);
              return indexPut(ops, o, p, s);
            };
            loadItem = function(item) {
              var id, p, type, v, vv, _results;
              if (!(item.id != null)) {
                throw MITHGrid.error("Item entry has no id: ", item);
              }
              if (!(item.type != null)) {
                throw MITHGrid.error("Item entry has no type: ", item);
              }
              id = item.id;
              type = item.type;
              if ($.isArray(id)) id = id[0];
              if ($.isArray(type)) type = type[0];
              set.add(id);
              id_list.push(id);
              indexFn(id, "type", type);
              indexFn(id, "id", id);
              _results = [];
              for (p in item) {
                v = item[p];
                if (typeof p !== "string") continue;
                if (p !== "id" && p !== "type") {
                  if ($.isArray(v)) {
                    _results.push((function() {
                      var _i, _len, _results2;
                      _results2 = [];
                      for (_i = 0, _len = v.length; _i < _len; _i++) {
                        vv = v[_i];
                        _results2.push(indexFn(id, p, vv));
                      }
                      return _results2;
                    })());
                  } else if (v != null) {
                    _results.push(indexFn(id, p, v));
                  } else {
                    _results.push(void 0);
                  }
                } else {
                  _results.push(void 0);
                }
              }
              return _results;
            };
            that.events.onBeforeLoading.fire(that);
            n = items.length;
            if (endFn != null) {
              chunk_size = parseInt(n / 100, 10);
              if (chunk_size > 200) chunk_size = 200;
            } else {
              chunk_size = n;
            }
            if (chunk_size < 1) chunk_size = 1;
            f = function(start) {
              var end, entry, i;
              end = start + chunk_size;
              if (end > n) end = n;
              for (i = start; start <= end ? i < end : i > end; start <= end ? i++ : i--) {
                entry = items[i];
                if (typeof entry === "object") loadItem(entry);
              }
              if (end < n) {
                return setTimeout(function() {
                  return f(end);
                }, 0);
              } else {
                that.events.onAfterLoading.fire(that);
                that.events.onModelChange.fire(that, id_list);
                if (endFn != null) return setTimeout(endFn, 0);
              }
            };
            return f(0);
          };
          that.prepare = function(expressions) {
            var ex, parsed, parser, valueType;
            parser = MITHGrid.Expression.initParser();
            parsed = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = expressions.length; _i < _len; _i++) {
                ex = expressions[_i];
                _results.push(parser.parse(ex));
              }
              return _results;
            })();
            valueType = void 0;
            return {
              evaluate: function(id) {
                var ex, values, _fn, _i, _len;
                values = [];
                valueType = void 0;
                _fn = function(ex) {
                  var items;
                  items = ex.evaluateOnItem(id, that);
                  valueType || (valueType = items.valueType);
                  return values = values.concat(items.values.items());
                };
                for (_i = 0, _len = parsed.length; _i < _len; _i++) {
                  ex = parsed[_i];
                  _fn(ex);
                }
                return values;
              },
              valueType: function() {
                return valueType;
              }
            };
          };
          that.getObjectsUnion = function(subjects, p, set, filter) {
            return getUnion(spo, subjects, p, set, filter);
          };
          that.getSubjectsUnion = function(objects, p, set, filter) {
            return getUnion(ops, objects, p, set, filter);
          };
          that.registerPresentation = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return ob.eventModelChange(that, that.items());
          };
          return that;
        };
      });
      Data.namespace('View', function(View) {
        return View.initInstance = function(options) {
          var expressions, filterItem, filterItems, intermediateDataStore, prevEventModelChange, set, subjectSet, that, _ref4, _ref5;
          that = MITHGrid.initView("MITHGrid.Data.View", options);
          set = Data.initSet();
          filterItem = function(id) {
            return false !== that.events.onFilterItem.fire(that.dataStore, id);
          };
          filterItems = function(endFn) {
            var chunk_size, f, ids, n;
            ids = that.dataStore.items();
            n = ids.length;
            if (n === 0) {
              endFn();
              return;
            }
            if (n > 200) {
              chunk_size = parseInt(n / 100, 10);
              if (chunk_size > 200) chunk_size = 200;
            } else {
              chunk_size = n;
            }
            if (chunk_size < 1) chunk_size = 1;
            f = function(start) {
              var end, i, id;
              end = start + chunk_size;
              if (end > n) end = n;
              for (i = start; start <= end ? i < end : i > end; start <= end ? i++ : i--) {
                id = ids[i];
                if (filterItem(id)) {
                  set.add(id);
                } else {
                  set.remove(id);
                }
              }
              if (end < n) {
                return setTimeout(function() {
                  return f(end);
                }, 0);
              } else {
                that.items = set.items;
                that.size = set.size;
                that.contains = set.contains;
                that.visit = set.visit;
                if (endFn != null) return setTimeout(endFn, 0);
              }
            };
            return f(0);
          };
          that.registerFilter = function(ob) {
            that.events.onFilterItem.addListener(function(x, y) {
              return ob.eventFilterItem(x, y);
            });
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return ob.events.onFilterChange.addListener(that.eventFilterChange);
          };
          that.registerPresentation = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return filterItems(function() {
              return ob.eventModelChange(that, that.items());
            });
          };
          that.items = set.items;
          that.contains = set.contains;
          that.visit = set.visit;
          that.size = set.size;
          that.eventFilterChange = function() {
            var current_set;
            current_set = Data.initSet(that.items());
            return filterItems(function() {
              var changed_set, i, _i, _j, _len, _len2, _ref4, _ref5;
              changed_set = Data.initSet();
              _ref4 = current_set.items();
              for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
                i = _ref4[_i];
                if (!that.contains(i)) changed_set.add(i);
              }
              _ref5 = that.items();
              for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
                i = _ref5[_j];
                if (!current_set.contains(i)) changed_set.add(i);
              }
              if (changed_set.size() > 0) {
                return that.events.onModelChange.fire(that, changed_set.items());
              }
            });
          };
          that.eventModelChange = function(model, items) {
            var changed_set, id, _i, _len;
            changed_set = Data.initSet();
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              id = items[_i];
              if (model.contains(id)) {
                if (filterItem(id)) {
                  set.add(id);
                  changed_set.add(id);
                } else {
                  if (set.contains(id)) {
                    changed_set.add(id);
                    set.remove(id);
                  }
                }
              } else {
                changed_set.add(id);
                set.remove(id);
              }
            }
            if (changed_set.size() > 0) {
              return that.events.onModelChange.fire(that, changed_set.items());
            }
          };
          if ((options != null ? (_ref4 = options.types) != null ? _ref4.length : void 0 : void 0) > 0) {
            (function(types) {
              return that.registerFilter({
                eventFilterItem: function(model, id) {
                  var item, t, _i, _len;
                  item = model.getItem(id);
                  if (!(item.type != null)) return false;
                  for (_i = 0, _len = types.length; _i < _len; _i++) {
                    t = types[_i];
                    if (__indexOf.call(item.type, t) >= 0) return;
                  }
                  return false;
                },
                eventModelChange: function(x, y) {},
                events: {
                  onFilterChange: {
                    addListener: function(x) {}
                  }
                }
              });
            })(options.types);
          }
          if ((options != null ? (_ref5 = options.filters) != null ? _ref5.length : void 0 : void 0) > 0) {
            (function(filters) {
              var ex, parsedFilters, parser;
              parser = MITHGrid.Expression.initParser();
              parsedFilters = (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = filters.length; _i < _len; _i++) {
                  ex = filters[_i];
                  _results.push(parser.parse(ex));
                }
                return _results;
              })();
              return that.registerFilter({
                eventFilterItem: function(model, id) {
                  var ex, v, values, _i, _j, _len, _len2;
                  for (_i = 0, _len = parsedFilters.length; _i < _len; _i++) {
                    ex = parsedFilters[_i];
                    values = ex.evaluateOnItem(id, model);
                    values = values.values.items();
                    for (_j = 0, _len2 = values.length; _j < _len2; _j++) {
                      v = values[_j];
                      if (v !== "false") return;
                    }
                  }
                  return false;
                },
                eventModelChange: function(x, y) {},
                events: {
                  onFilterChange: {
                    addListener: function(x) {}
                  }
                }
              });
            })(options.filters);
          }
          if ((options != null ? options.collection : void 0) != null) {
            that.registerFilter({
              eventFilterItem: options.collection,
              eventModelChange: function(x, y) {},
              events: {
                onFilterChange: {
                  addListener: function(x) {}
                }
              }
            });
          }
          if ((options != null ? options.expressions : void 0) != null) {
            expressions = options.dataStore.prepare(options.expressions);
            prevEventModelChange = that.eventModelChange;
            intermediateDataStore = MITHGrid.Data.initStore({});
            subjectSet = MITHGrid.Data.initSet();
            that.eventModelChange = function(model, items) {
              var id, idSet, intermediateSet, item, itemList, itemSet, removedItems, v, _i, _j, _len, _len2, _ref6;
              itemList = [];
              removedItems = [];
              intermediateSet = MITHGrid.Data.initSet();
              intermediateSet = intermediateDataStore.getObjectsUnion(subjectSet, "mapsTo", intermediateSet);
              for (_i = 0, _len = items.length; _i < _len; _i++) {
                id = items[_i];
                if (intermediateSet.contains(id)) {
                  itemList.push(id);
                  if (!model.contains(id)) {
                    idSet = MITHGrid.Data.initSet();
                    intermediateDataStore.getSubjectsUnion(MITHGrid.Data.initSet([id]), "mapsTo", idSet);
                    idSet.visit(function(x) {
                      var i, item, mapsTo;
                      item = intermediateDataStore.getItem(x);
                      mapsTo = item.mapsTo;
                      if (mapsTo != null) {
                        i = mapsTo.indexOf(id);
                        if (i === 0) {
                          mapsTo = mapsTo.slice(1, mapsTo.length);
                        } else if (i === mapsTo.length - 1) {
                          mapsTo = mapsTo.slice(0, (mapsTo.length - 1));
                        } else if (i > -1) {
                          mapsTo = mapsTo.slice(0, i).concat(mapsTo.slice(i + 1, mapsTo.length));
                        }
                        return intermediateDataStore.updateItems([
                          {
                            id: x,
                            mapsTo: mapsTo
                          }
                        ]);
                      }
                    });
                  }
                } else if (model.contains(id)) {
                  itemSet = MITHGrid.Data.initSet();
                  _ref6 = expressions.evaluate([id]);
                  for (_j = 0, _len2 = _ref6.length; _j < _len2; _j++) {
                    v = _ref6[_j];
                    itemSet.add(v);
                  }
                  if (intermediateDataStore.contains(id)) {
                    intermediateDataStore.updateItems([
                      {
                        id: id,
                        mapsTo: itemSet.items()
                      }
                    ]);
                  } else {
                    intermediateDataStore.loadItems([
                      {
                        id: id,
                        mapsTo: itemSet.items()
                      }
                    ]);
                  }
                } else {
                  itemList = itemList.concat(intermediateDataStore.getItem(id).mapsTo);
                  removedItems.push(id);
                }
              }
              if (removedItems.length > 0) {
                intermediateDataStore.removeItems(removedItems);
              }
              intermediateSet = MITHGrid.Data.initSet();
              intermediateDataStore.getObjectsUnion(subjectSet, "mapsTo", intermediateSet);
              itemList = (function() {
                var _k, _len3, _results;
                _results = [];
                for (_k = 0, _len3 = itemList.length; _k < _len3; _k++) {
                  item = itemList[_k];
                  if (__indexOf.call(items, item) >= 0) _results.push(item);
                }
                return _results;
              })();
              return prevEventModelChange(intermediateSet, itemList);
            };
          }
          that.dataStore = options.dataStore;
          that.getItems = that.dataStore.getItems;
          that.getItem = that.dataStore.getItem;
          that.removeItems = that.dataStore.removeItems;
          that.updateItems = that.dataStore.updateItems;
          that.loadItems = that.dataStore.loadItems;
          that.prepare = that.dataStore.prepare;
          that.addType = that.dataStore.addType;
          that.getType = that.dataStore.getType;
          that.addProperty = that.dataStore.addProperty;
          that.getProperty = that.dataStore.getProperty;
          that.getObjectsUnion = that.dataStore.getObjectsUnion;
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion;
          that.dataStore.events.onModelChange.addListener(that.eventModelChange);
          that.eventModelChange(that.dataStore, that.dataStore.items());
          return that;
        };
      });
      Data.namespace('SubSet', function(SubSet) {
        return SubSet.initInstance = function(options) {
          var expressions, key, set, that;
          that = MITHGrid.initView("MITHGrid.Data.SubSet", options);
          options = that.options;
          key = options.key;
          set = Data.initSet();
          that.items = set.items;
          that.contains = set.contains;
          that.visit = set.visit;
          that.size = set.size;
          that.setKey = function(k) {
            key = k;
            return that.eventModelChange(options.dataStore, options.dataStore.items());
          };
          expressions = options.dataStore.prepare(options.expressions);
          that.eventModelChange = function(model, items) {
            var changed, i, newItems, _i, _len;
            if (key != null) {
              newItems = Data.initSet(expressions.evaluate([key]));
            } else {
              newItems = Data.initSet();
            }
            changed = [];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              i = items[_i];
              if (set.contains(i)) {
                changed.push(i);
                if (!newItems.contains(i)) set.remove(i);
              } else if (newItems.contains(i)) {
                set.add(i);
                changed.push(i);
              }
            }
            if (changed.length > 0) {
              return that.events.onModelChange.fire(that, changed);
            }
          };
          that.dataStore = options.dataStore;
          that.getItems = that.dataStore.getItems;
          that.getItem = that.dataStore.getItem;
          that.removeItems = that.dataStore.removeItems;
          that.fetchData = that.dataStore.fetchData;
          that.updateItems = that.dataStore.updateItems;
          that.loadItems = that.dataStore.loadItems;
          that.prepare = that.dataStore.prepare;
          that.addType = that.dataStore.addType;
          that.getType = that.dataStore.getType;
          that.addProperty = that.dataStore.addProperty;
          that.getProperty = that.dataStore.getProperty;
          that.getObjectsUnion = that.dataStore.getObjectsUnion;
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion;
          that.dataStore.events.onModelChange.addListener(that.eventModelChange);
          that.eventModelChange(that.dataStore, that.dataStore.items());
          that.registerPresentation = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return setTimeout(function() {
              return ob.eventModelChange(that, that.items());
            }, 0);
          };
          return that;
        };
      });
      Data.namespace('ListPager', function(ListPager) {
        return ListPager.initInstance = function(options) {
          var findItemPosition, itemList, itemListStart, itemListStop, leftKey, rightKey, set, that;
          that = MITHGrid.initInstance("MITHGrid.Data.ListPager", options);
          options = that.options;
          itemList = [];
          itemListStart = 0;
          itemListStop = -1;
          leftKey = void 0;
          rightKey = void 0;
          findItemPosition = function(itemId) {
            return itemList.indexOf(itemId);
          };
          set = Data.initSet();
          that.items = set.items;
          that.size = set.size;
          that.contains = set.contains;
          that.visit = set.visit;
          that.dataStore = options.dataStore;
          that.getItems = that.dataStore.getItems;
          that.getItem = that.dataStore.getItem;
          that.removeItems = that.dataStore.removeItems;
          that.fetchData = that.dataStore.fetchData;
          that.updateItems = that.dataStore.updateItems;
          that.loadItems = that.dataStore.loadItems;
          that.prepare = that.dataStore.prepare;
          that.addType = that.dataStore.addType;
          that.getType = that.dataStore.getType;
          that.addProperty = that.dataStore.addProperty;
          that.getProperty = that.dataStore.getProperty;
          that.getObjectsUnion = that.dataStore.getObjectsUnion;
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion;
          that.setList = function(idList) {
            var changedItems, id, _i, _j, _len, _len2, _ref4, _ref5, _ref6;
            itemList = idList;
            changedItems = [];
            for (_i = 0, _len = itemList.length; _i < _len; _i++) {
              id = itemList[_i];
              if (that.dataStore.contains(id) && !set.contains(id)) {
                if ((itemListStart <= (_ref4 = itemList.indexOf(id)) && _ref4 < itemListStop)) {
                  changedItems.push(id);
                  set.add(id);
                }
              } else if (set.contains(id) && !that.dataStore.contains(id)) {
                changedItems.push(id);
                set.remove(id);
              }
            }
            _ref5 = set.items();
            for (_j = 0, _len2 = _ref5.length; _j < _len2; _j++) {
              id = _ref5[_j];
              if ((_ref6 = !id, __indexOf.call(itemList, _ref6) >= 0) || !that.dataStore.contains(id)) {
                changedItems.push(id);
                set.remove(id);
              }
            }
            if (changedItems.length > 0) {
              return that.events.onModelChange.fire(that, changedItems);
            }
          };
          that.eventModelChange = function(model, items) {
            var changedItems, itemId, key, _i, _len;
            changedItems = [];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              itemId = items[_i];
              if (model.contains(itemId)) {
                key = findItemPosition(itemId);
                if (set.contains(itemId)) {
                  changedItems.push(itemId);
                  if (!((itemListStart <= key && key < itemListStop))) {
                    set.remove(itemId);
                  }
                } else {
                  if ((itemListStart <= key && key < itemListStop)) {
                    set.add(itemId);
                    changedItems.push(itemId);
                  }
                }
              } else {
                set.remove(itemId);
                changedItems.push(itemId);
              }
            }
            if (changedItems.length > 0) {
              return that.events.onModelChange.fire(that, changedItems);
            }
          };
          that.setKeyRange = function(l, r) {
            var changedItems, i, itemId, oldSet;
            if (l < r) {
              itemListStart = l;
              itemListStop = r;
            } else {
              itemListStart = r;
              itemListStop = l;
            }
            oldSet = set;
            changedItems = Data.initSet();
            set = Data.initSet();
            that.items = set.items;
            that.size = set.size;
            that.contains = set.contains;
            that.visit = set.visit;
            if (itemListStart < itemListStop) {
              for (i = itemListStart; itemListStart <= itemListStop ? i <= itemListStop : i >= itemListStop; itemListStart <= itemListStop ? i++ : i--) {
                itemId = itemList[i];
                if (!oldSet.contains(itemId)) changedItems.add(itemId);
                set.add(itemId);
              }
            }
            oldSet.visit(function(x) {
              if (!set.contains(x)) return changedItems.add(x);
            });
            if (changedItems.size() > 0) {
              return that.events.onModelChange.fire(that, changedItems.items());
            }
          };
          that.dataStore.registerPresentation(that);
          that.registerPresentation = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return ob.eventModelChange(that, that.items());
          };
          return that;
        };
      });
      Data.namespace('Pager', function(Pager) {
        return Pager.initInstance = function(options) {
          var expressions, findItemPosition, findLeftPoint, findRightPoint, itemList, itemListStart, itemListStop, leftKey, rightKey, set, that;
          that = MITHGrid.initInstance("MITHGrid.Data.Pager", options);
          options = that.options;
          itemList = [];
          itemListStart = -1;
          itemListStop = -1;
          leftKey = void 0;
          rightKey = void 0;
          findLeftPoint = function(key) {
            var left, mid, right;
            if (!(key != null)) return 0;
            left = 0;
            if (key != null) {
              right = itemList.length - 1;
              while (left < right) {
                mid = ~~((left + right) / 2);
                if (itemList[mid][0] < key) {
                  left = mid + 1;
                } else if (itemList[mid][0] === key) {
                  right = mid;
                } else {
                  right = mid - 1;
                }
              }
            }
            return left;
          };
          findRightPoint = function(key) {
            var left, mid, right;
            if (!(key != null)) return itemList.length - 1;
            left = 0;
            right = itemList.length - 1;
            if (key != null) {
              while (left < right) {
                mid = ~~((left + right) / 2);
                if (itemList[mid][0] <= key) {
                  left = mid + 1;
                } else {
                  right = mid - 1;
                }
              }
            }
            return right;
          };
          findItemPosition = function(itemId) {
            var i, _ref4;
            for (i = 0, _ref4 = itemList.length; 0 <= _ref4 ? i < _ref4 : i > _ref4; 0 <= _ref4 ? i++ : i--) {
              if (itemList[i][1] === itemId) return i;
            }
            return -1;
          };
          set = Data.initSet();
          that.items = set.items;
          that.size = set.size;
          that.contains = set.contains;
          that.visit = set.visit;
          that.dataStore = options.dataStore;
          that.getItems = that.dataStore.getItems;
          that.getItem = that.dataStore.getItem;
          that.removeItems = that.dataStore.removeItems;
          that.fetchData = that.dataStore.fetchData;
          that.updateItems = that.dataStore.updateItems;
          that.loadItems = that.dataStore.loadItems;
          that.prepare = that.dataStore.prepare;
          that.addType = that.dataStore.addType;
          that.getType = that.dataStore.getType;
          that.addProperty = that.dataStore.addProperty;
          that.getProperty = that.dataStore.getProperty;
          that.getObjectsUnion = that.dataStore.getObjectsUnion;
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion;
          expressions = that.prepare(options.expressions);
          that.eventModelChange = function(model, items) {
            var changedItems, i, itemId, key, keys, _i, _len;
            changedItems = [];
            for (_i = 0, _len = items.length; _i < _len; _i++) {
              itemId = items[_i];
              if (model.contains(itemId)) {
                keys = expressions.evaluate(itemId);
                if (keys.length > 0) {
                  if (expressions.valueType() === "numeric") {
                    key = parseFloat(keys[0]);
                  } else {
                    key = keys[0];
                  }
                  if (set.contains(itemId)) {
                    i = findItemPosition(itemId);
                    if (i === -1) {
                      itemList.push([key, itemId]);
                    } else {
                      itemList[i][0] = key;
                    }
                    changedItems.push(itemId);
                    if ((leftKey != null) && key < leftKey || (rightKey != null) && key > rightKey) {
                      set.remove(itemId);
                    }
                  } else {
                    itemList.push([key, itemId]);
                    if ((!(leftKey != null) || key >= leftKey) && (!(rightKey != null) || key <= rightKey)) {
                      set.add(itemId);
                      changedItems.push(itemId);
                    }
                  }
                } else {
                  if (set.contains(itemId)) {
                    i = findItemPosition(itemId);
                    if (i === 0) {
                      itemList = itemList.slice(1, itemList.length);
                    } else if (i === itemList.length - 1) {
                      itemList = itemList.slice(0, (itemList.length - 1));
                    } else if (i !== -1) {
                      itemList = itemList.slice(0, i).concat(itemList.slice(i + 1, itemList.length));
                    }
                    set.remove(itemId);
                    changedItems.push(itemId);
                  }
                }
              } else {
                set.remove(itemId);
                changedItems.push(itemId);
              }
            }
            itemList.sort(function(a, b) {
              if (a[0] < b[0]) return -1;
              if (a[0] > b[0]) return 1;
              return 0;
            });
            itemListStart = findLeftPoint(leftKey);
            itemListStop = findRightPoint(rightKey);
            if (changedItems.length > 0) {
              return that.events.onModelChange.fire(that, changedItems);
            }
          };
          that.setKeyRange = function(l, r) {
            var changedItems, i, itemId, oldSet;
            if ((l != null) && (r != null)) {
              if (l < r) {
                leftKey = l;
                rightKey = r;
              } else {
                leftKey = r;
                rightKey = l;
              }
            } else {
              leftKey = l;
              rightKey = r;
            }
            itemListStart = findLeftPoint(leftKey);
            itemListStop = findRightPoint(rightKey);
            changedItems = Data.initSet();
            oldSet = set;
            set = Data.initSet();
            that.items = set.items;
            that.size = set.size;
            that.contains = set.contains;
            that.visit = set.visit;
            if (itemListStart < itemListStop) {
              for (i = itemListStart; itemListStart <= itemListStop ? i <= itemListStop : i >= itemListStop; itemListStart <= itemListStop ? i++ : i--) {
                itemId = itemList[i][1];
                if (!oldSet.contains(itemId)) changedItems.add(itemId);
                set.add(itemId);
              }
            }
            oldSet.visit(function(x) {
              if (!set.contains(x)) return changedItems.add(x);
            });
            if (changedItems.size() > 0) {
              return that.events.onModelChange.fire(that, changedItems.items());
            }
          };
          that.dataStore.registerPresentation(that);
          that.registerPresentation = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return ob.eventModelChange(that, that.items());
          };
          return that;
        };
      });
      return Data.namespace('RangePager', function(RangePager) {
        return RangePager.initInstance = function(options) {
          var leftPager, rightPager, set, that;
          that = MITHGrid.initInstance("MITHGrid.Data.RangePager", options);
          options = that.options;
          leftPager = Data.Pager.initInstance({
            dataStore: options.dataStore,
            expressions: options.leftExpressions
          });
          rightPager = Data.Pager.initInstance({
            dataStore: options.dataStore,
            expressions: options.rightExpressions
          });
          set = Data.initSet();
          that.items = set.items;
          that.size = set.size;
          that.contains = set.contains;
          that.visit = set.visit;
          that.dataStore = options.dataStore;
          that.getItems = that.dataStore.getItems;
          that.getItem = that.dataStore.getItem;
          that.removeItems = that.dataStore.removeItems;
          that.fetchData = that.dataStore.fetchData;
          that.updateItems = that.dataStore.updateItems;
          that.loadItems = that.dataStore.loadItems;
          that.prepare = that.dataStore.prepare;
          that.addType = that.dataStore.addType;
          that.getType = that.dataStore.getType;
          that.addProperty = that.dataStore.addProperty;
          that.getProperty = that.dataStore.getProperty;
          that.getObjectsUnion = that.dataStore.getObjectsUnion;
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion;
          that.eventModelChange = function(model, itemIds) {
            var changedIds, id, _i, _len;
            changedIds = [];
            for (_i = 0, _len = itemIds.length; _i < _len; _i++) {
              id = itemIds[_i];
              if (leftPager.contains(id) && rightPager.contains(id)) {
                changedIds.push(id);
                set.add(id);
              } else {
                if (set.contains(id)) changedIds.push(id);
                set.remove(id);
              }
            }
            if (changedIds.length > 0) {
              return that.events.onModelChange.fire(that, changedIds);
            }
          };
          that.setKeyRange = function(l, r) {
            var _ref4;
            if (l > r) _ref4 = [r, l], l = _ref4[0], r = _ref4[1];
            leftPager.setKeyRange(void 0, r);
            return rightPager.setKeyRange(l, void 0);
          };
          that.setKeyRange(void 0, void 0);
          leftPager.registerPresentation(that);
          rightPager.registerPresentation(that);
          that.registerPresentation = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
              return ob.eventModelChange(m, i);
            });
            return ob.eventModelChange(that, that.items());
          };
          return that;
        };
      });
    });
    MITHGrid.namespace("Expression", function(exports) {
      var Expression, _operators;
      Expression = {};
      _operators = {
        "+": {
          argumentType: "number",
          valueType: "number",
          f: function(a, b) {
            return a + b;
          }
        },
        "-": {
          argumentType: "number",
          valueType: "number",
          f: function(a, b) {
            return a - b;
          }
        },
        "*": {
          argumentType: "number",
          valueType: "number",
          f: function(a, b) {
            return a * b;
          }
        },
        "/": {
          argumentType: "number",
          valueType: "number",
          f: function(a, b) {
            return a / b;
          }
        },
        "=": {
          valueType: "boolean",
          f: function(a, b) {
            return a === b;
          }
        },
        "<>": {
          valueType: "boolean",
          f: function(a, b) {
            return a !== b;
          }
        },
        "><": {
          valueType: "boolean",
          f: function(a, b) {
            return a !== b;
          }
        },
        "<": {
          valueType: "boolean",
          f: function(a, b) {
            return a < b;
          }
        },
        ">": {
          valueType: "boolean",
          f: function(a, b) {
            return a > b;
          }
        },
        "<=": {
          valueType: "boolean",
          f: function(a, b) {
            return a <= b;
          }
        },
        ">=": {
          valueType: "boolean",
          f: function(a, b) {
            return a >= b;
          }
        }
      };
      Expression.controls = exports.controls = {
        "if": {
          f: function(args, roots, rootValueTypes, defaultRootName, database) {
            var condition, conditionCollection;
            conditionCollection = args[0].evaluate(roots, rootValueTypes, defaultRootName, database);
            condition = false;
            conditionCollection.forEachValue(function(v) {
              if (v) {
                condition = true;
                return true;
              } else {

              }
            });
            if (condition) {
              return args[1].evaluate(roots, rootValueTypes, defaultRootName, database);
            } else {
              return args[2].evaluate(roots, rootValueTypes, defaultRootName, database);
            }
          }
        },
        "foreach": {
          f: function(args, roots, rootValueTypes, defaultRootName, database) {
            var collection, oldValue, oldValueType, results, valueType;
            collection = args[0].evaluate(roots, rootValueTypes, defaultRootName, database);
            oldValue = roots.value;
            oldValueType = rootValueTypes.value;
            results = [];
            valueType = "text";
            rootValueTypes.value = collection.valueType;
            collection.forEachValue(function(element) {
              var collection2;
              roots.value = element;
              collection2 = args[1].evaluate(roots, rootValueTypes, defaultRootName, database);
              valueType = collection2.valueType;
              return collection2.forEachValue(function(result) {
                return results.push(result);
              });
            });
            roots.value = oldValue;
            rootValueTypes.value = oldValueType;
            return Expression.initCollection(results, valueType);
          }
        },
        "default": {
          f: function(args, roots, rootValueTypes, defaultRootName, database) {
            var arg, collection, _i, _len;
            for (_i = 0, _len = args.length; _i < _len; _i++) {
              arg = args[_i];
              collection = arg.evaluate(roots, rootValueTypes, defaultRootName, database);
              if (collection.size() > 0) return collection;
            }
            return Expression.initCollection([], "text");
          }
        }
      };
      Expression.initExpression = function(rootNode) {
        var that;
        that = {};
        that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
          var collection;
          collection = rootNode.evaluate(roots, rootValueTypes, defaultRootName, database);
          return {
            values: collection.getSet(),
            valueType: collection.valueType,
            size: collection.size
          };
        };
        that.evaluateOnItem = function(itemID, database) {
          return this.evaluate({
            "value": itemID
          }, {
            "value": "item"
          }, "value", database);
        };
        that.evaluateSingle = function(roots, rootValueTypes, defaultRootName, database) {
          var collection, result;
          collection = rootNode.evaluate(roots, rootValueTypes, defaultRootName, database);
          result = {
            value: null,
            valueType: collection.valueType
          };
          collection.forEachValue(function(v) {
            result.value = v;
            return true;
          });
          return result;
        };
        that.isPath = rootNode.isPath;
        if (that.isPath) {
          that.getPath = function() {
            return rootNode;
          };
          that.testExists = function(roots, rootValueTypes, defaultRootName, database) {
            return rootNode.testExists(roots, rootValueTypes, defaultRootName, database);
          };
        } else {
          that.getPath = function() {
            return null;
          };
          that.testExists = function(roots, rootValueTypes, defaultRootName, database) {
            return that.evaluate(roots, rootValueTypes, defaultRootName, database).values.size() > 0;
          };
        }
        that.evaluateBackward = function(value, valueType, filter, database) {
          return rootNode.walkBackward([value], valueType, filter, database);
        };
        that.walkForward = function(values, valueType, database) {
          return rootNode.walkForward(values, valueType, database);
        };
        that.walkBackward = function(values, valueType, filter, database) {
          return rootNode.walkBackward(values, valueType, filter, database);
        };
        return that;
      };
      Expression.initCollection = exports.initCollection = function(values, valueType) {
        var that;
        that = {
          valueType: valueType
        };
        if (values instanceof Array) {
          that.forEachValue = function(f) {
            var v, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = values.length; _i < _len; _i++) {
              v = values[_i];
              if (f(v) === true) {
                break;
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          };
          that.getSet = function() {
            return MITHGrid.Data.initSet(values);
          };
          that.contains = function(v) {
            return __indexOf.call(values, v) >= 0;
          };
          that.size = function() {
            return values.length;
          };
        } else {
          that.forEachValue = values.visit;
          that.size = values.size;
          that.getSet = function() {
            return values;
          };
          that.contains = values.contains;
        }
        that.isPath = false;
        return that;
      };
      Expression.initConstant = function(value, valueType) {
        var that;
        that = {};
        that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
          return Expression.initCollection([value], valueType);
        };
        that.isPath = false;
        return that;
      };
      Expression.initOperator = function(operator, args) {
        var that, _args, _operator;
        that = {};
        _operator = operator;
        _args = args;
        that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
          var a, f, values, _i, _len;
          values = [];
          args = [];
          for (_i = 0, _len = _args.length; _i < _len; _i++) {
            a = _args[_i];
            args.push(a.evaluate(roots, rootValueTypes, defaultRootName, database));
          }
          operator = _operators[_operator];
          f = operator.f;
          if (operator.argumentType === "number") {
            args[0].forEachValue(function(v1) {
              if (typeof v1 !== "number") v1 = parseFloat(v1);
              return args[1].forEachValue(function(v2) {
                if (typeof v2 !== "number") v2 = parseFloat(v2);
                return values.push(f(v1, v2));
              });
            });
          } else {
            args[0].forEachValue(function(v1) {
              return args[1].forEachValue(function(v2) {
                return values.push(f(v1, v2));
              });
            });
          }
          return Expression.initCollection(values, operator.valueType);
        };
        that.isPath = false;
        return that;
      };
      Expression.initFunctionCall = function(name, args) {
        var that, _args;
        that = {};
        _args = args;
        that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
          var a, _i, _len, _ref4;
          args = [];
          for (_i = 0, _len = _args.length; _i < _len; _i++) {
            a = _args[_i];
            args.push(a.evaluate(roots, rootValueTypes, defaultRootName, database));
          }
          if (((_ref4 = Expression.functions[name]) != null ? _ref4.f : void 0) != null) {
            return Expression.functions[name].f(args);
          } else {
            throw new Error("No such function named " + _name);
          }
        };
        that.isPath = false;
        return that;
      };
      Expression.initControlCall = function(name, args) {
        var that;
        that = {};
        that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
          return Expression.controls[name].f(args, roots, rootValueTypes, defaultRootName, database);
        };
        that.isPath = false;
        return that;
      };
      Expression.initPath = function(property, forward) {
        var that, walkBackward, walkForward, _rootName, _segments;
        that = {};
        _rootName = null;
        _segments = [];
        walkForward = function(collection, database) {
          var a, backwardArraySegmentFn, forwardArraySegmentFn, i, segment, valueType, values, _ref4;
          forwardArraySegmentFn = function(segment) {
            var a;
            a = [];
            collection.forEachValue(function(v) {
              return database.getObjects(v, segment.property).visit(function(v2) {
                return a.push(v2);
              });
            });
            return a;
          };
          backwardArraySegmentFn = function(segment) {
            var a;
            a = [];
            collection.forEachValue(function(v) {
              return database.getSubjects(v, segment.property).visit(function(v2) {
                return a.push(v2);
              });
            });
            return a;
          };
          for (i = 0, _ref4 = _segments.length; 0 <= _ref4 ? i < _ref4 : i > _ref4; 0 <= _ref4 ? i++ : i--) {
            segment = _segments[i];
            if (segment.isMultiple) {
              a = [];
              if (segment.forward) {
                a = forwardArraySegmentFn(segment);
                property = database.getProperty(segment.property);
                valueType = property != null ? property.getValueType() : "text";
              } else {
                a = backwardArraySegmentFn(segment);
                valueType = "item";
              }
              collection = Expression.initCollection(a, valueType);
            } else {
              if (segment.forward) {
                values = database.getObjectsUnion(collection.getSet(), segment.property);
                property = database.getProperty(segment.property);
                valueType = property != null ? property.getValueType() : "text";
                collection = Expression.initCollection(values, valueType);
              } else {
                values = database.getSubjectsUnion(collection.getSet(), segment.property);
                collection = Expression.initCollection(values, "item");
              }
            }
          }
          return collection;
        };
        walkBackward = function(collection, filter, database) {
          var a, backwardArraySegmentFn, forwardArraySegmentFn, i, segment, valueType, values, _ref4;
          forwardArraySegmentFn = function(segment) {
            var a;
            a = [];
            collection.forEachValue(function(v) {
              return database.getSubjects(v, segment.property).visit(function(v2) {
                if (i > 0 || !(filter != null) || filter.contains(v2)) {
                  return a.push(v2);
                }
              });
            });
            return a;
          };
          backwardArraySegmentFn = function(segment) {
            var a;
            a = [];
            collection.forEachValue(function(v) {
              return database.getObjects(v, segment.property).visit(function(v2) {
                if (i > 0 || !(filter != null) || filter.contains(v2)) {
                  return a.push(v2);
                }
              });
            });
            return a;
          };
          if (filter instanceof Array) filter = MITHGrid.Data.initSet(filter);
          for (i = _ref4 = _segments.length - 1; _ref4 <= 0 ? i <= 0 : i >= 0; _ref4 <= 0 ? i++ : i--) {
            segment = _segments[i];
            if (segment.isMultiple) {
              a = [];
              if (segment.forward) {
                a = forwardArraySegmentFn(segment);
                property = database.getProperty(segment.property);
                valueType = property != null ? property.getValueType() : "text";
              } else {
                a = backwardArraySegmentFn(segment);
                valueType = "item";
              }
              collection = Expression.initCollection(a, valueType);
            } else if (segment.forward) {
              values = database.getSubjectsUnion(collection.getSet(), segment.property, null, i === 0 ? filter : null);
              collection = Expression.initCollection(values, "item");
            } else {
              values = database.getObjectsUnion(collection.getSet(), segment.property, null, i === 0 ? filter : null);
              property = database.getProperty(segment.property);
              valueType = property != null ? property.getValueType() : "text";
              collection = Expression.initCollection(values, valueType);
            }
          }
          return collection;
        };
        if (property != null) {
          _segments.push({
            property: property,
            forward: forward,
            isMultiple: false
          });
        }
        that.isPath = true;
        that.setRootName = function(rootName) {
          return _rootName = rootName;
        };
        that.appendSegment = function(property, hopOperator) {
          return _segments.push({
            property: property,
            forward: hopOperator[0] === ".",
            isMultiple: hopOperator.length > 1
          });
        };
        that.getSegment = function(index) {
          var segment;
          if (index < _segments.length) {
            segment = _segments[index];
            return {
              property: segment.property,
              forward: segment.forward,
              isMultiple: segment.isMultiple
            };
          } else {
            return null;
          }
        };
        that.getLastSegment = function() {
          return that.getSegment(_segments.length - 1);
        };
        that.getSegmentCount = function() {
          return _segments.length;
        };
        that.rangeBackward = function(from, to, filter, database) {
          var i, segment, set, valueType, _ref4;
          set = MITHGrid.Data.initSet();
          valueType = "item";
          if (_segments.length > 0) {
            segment = _segments[_segments.length - 1];
            if (segment.forward) {
              database.getSubjectsInRange(segment.property, from, to, false, set, _segments.length === 1 ? filter : null);
            } else {
              throw new Error("Last path of segment must be forward");
            }
            for (i = _ref4 = _segments.length - 2; _ref4 <= 0 ? i <= 0 : i >= 0; _ref4 <= 0 ? i++ : i--) {
              segment = _segments[i];
              if (segment.forward) {
                set = database.getSubjectsUnion(set, segment.property, null, i === 0 ? filter : null);
                valueType = "item";
              } else {
                set = database.getObjectsUnion(set, segment.property, null, i === 0 ? filter : null);
                property = database.getPropertysegment.property;
                valueType = property != null ? property.getValueType() : "text";
              }
            }
          }
          return {
            valueType: valueType,
            values: set,
            count: set.size()
          };
        };
        that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
          var collection, root, rootName, valueType;
          rootName = _rootName != null ? _rootName : defaultRootName;
          valueType = rootValueTypes[rootName] != null ? rootValueTypes[rootName] : "text";
          collection = null;
          if (roots[rootName] != null) {
            root = roots[rootName];
            if (root.isSet || root instanceof Array) {
              collection = Expression.initCollection(root, valueType);
            } else {
              collection = Expression.initCollection([root], valueType);
            }
            return walkForward(collection, database);
          } else {
            throw new Error("No such variable called " + rootName);
          }
        };
        that.testExists = function(roots, rootValueTypes, defaultRootName, database) {
          return that.evaluate(roots, rootValueTypes, defaultRootName, database).size() > 0;
        };
        that.evaluateBackward = function(value, valueType, filter, database) {
          var collection;
          collection = Expression.initCollection([value], valueType);
          return walkBackward(collection, filter, database);
        };
        that.walkForward = function(values, valueType, database) {
          return walkForward(Expression.initCollection(values, valueType), database);
        };
        that.walkBackward = function(values, valueType, filter, database) {
          return walkBackward(Expression.initCollection(values, valueType), filter, database);
        };
        return that;
      };
      Expression.initParser = exports.initParser = function() {
        var internalParse, that;
        that = {};
        internalParse = function(scanner, several) {
          var Scanner, expressions, makePosition, next, parseExpression, parseExpressionList, parseFactor, parsePath, parseSubExpression, parseTerm, r, roots, token, _i, _len;
          token = scanner.token();
          Scanner = Expression.initScanner;
          next = function() {
            scanner.next();
            return token = scanner.token();
          };
          parseTerm = function() {
            var operator, term, _ref4;
            term = parseFactor();
            while ((token != null) && token.type === Scanner.OPERATOR && ((_ref4 = token.value) === "*" || _ref4 === "/")) {
              operator = token.value;
              next();
              term = Expression.initOperator(operator, [term, parseFactor()]);
            }
            return term;
          };
          parseSubExpression = function() {
            var operator, subExpression, _ref4;
            subExpression = parseTerm();
            while ((token != null) && token.type === Scanner.OPERATOR && ((_ref4 = token.value) === "+" || _ref4 === "-")) {
              operator = token.value;
              next();
              subExpression = Expression.initOperator(operator, [subExpression, parseTerm()]);
            }
            return subExpression;
          };
          parseExpression = function() {
            var expression, operator, _ref4;
            expression = parseSubExpression();
            while ((token != null) && token.type === Scanner.OPERATOR && ((_ref4 = token.value) === "=" || _ref4 === "<>" || _ref4 === "<" || _ref4 === ">" || _ref4 === "<=" || _ref4 === ">=")) {
              operator = token.value;
              next();
              expression = Expression.initOperator(operator, [expression, parseSubExpression()]);
            }
            return expression;
          };
          parseExpressionList = function() {
            var expressions;
            expressions = [parseExpression()];
            while ((token != null) && token.type === Scanner.DELIMITER && token.value === ",") {
              next();
              expressions.push(parseExpression());
            }
            return expressions;
          };
          makePosition = function() {
            if (token != null) {
              return token.start;
            } else {
              return scanner.index();
            }
          };
          parsePath = function() {
            var hopOperator, path;
            path = Expression.initPath();
            while ((token != null) && token.type === Scanner.PATH_OPERATOR) {
              hopOperator = token.value;
              next();
              if ((token != null) && token.type === Scanner.IDENTIFIER) {
                path.appendSegment(token.value, hopOperator);
                next();
              } else {
                throw new Error("Missing property ID at position " + makePosition());
              }
            }
            return path;
          };
          parseFactor = function() {
            var args, identifier, result;
            result = null;
            args = [];
            if (!(token != null)) {
              throw new Error("Missing factor at end of expression");
            }
            switch (token.type) {
              case Scanner.NUMBER:
                result = Expression.initConstant(token.value, "number");
                next();
                break;
              case Scanner.STRING:
                result = Expression.initConstant(token.value, "text");
                next();
                break;
              case Scanner.PATH_OPERATOR:
                result = parsePath();
                break;
              case Scanner.IDENTIFIER:
                identifier = token.value;
                next();
                if (Expression.controls[identifier] != null) {
                  if ((token != null) && token.type === Scanner.DELIMITER && token.value === "(") {
                    next();
                    if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                      args = [];
                    } else {
                      args = parseExpressionList();
                    }
                    result = Expression.initControlCall(identifier, args);
                    if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                      next();
                    } else {
                      throw new Error("Missing ) to end " + identifier + " at position " + makePosition());
                    }
                  } else {
                    throw new Error("Missing ( to start " + identifier + " at position " + makePosition());
                  }
                } else {
                  if ((token != null) && token.type === Scanner.DELIMITER && token.value === "(") {
                    next();
                    if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                      args = [];
                    } else {
                      args = parseExpressionList();
                    }
                    result = Expression.initFunctionCall(identifier, args);
                    if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                      next();
                    } else {
                      throw new Error("Missing ) after function call " + identifier + " at position " + makePosition());
                    }
                  } else {
                    result = parsePath();
                    result.setRootName(identifier);
                  }
                }
                break;
              case Scanner.DELIMITER:
                if (token.value === "(") {
                  next();
                  result = parseExpression();
                  if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                    next();
                  } else {
                    throw new Error("Missing ) at position " + makePosition());
                  }
                } else {
                  throw new Error("Unexpected text " + token.value + " at position " + makePosition());
                }
                break;
              default:
                throw new Error("Unexpected text " + token.value + " at position " + makePosition());
            }
            return result;
          };
          if (several) {
            roots = parseExpressionList();
            expressions = [];
            for (_i = 0, _len = roots.length; _i < _len; _i++) {
              r = roots[_i];
              expressions.push(Expression.initExpression(r));
            }
            return expressions;
          } else {
            return [Expression.initExpression(parseExpression())];
          }
        };
        that.parse = function(s, startIndex, results) {
          var scanner;
          if (startIndex == null) startIndex = 0;
          if (results == null) results = {};
          scanner = Expression.initScanner(s, startIndex);
          try {
            return internalParse(scanner, false)[0];
          } finally {
            results.index = scanner.token() != null ? scanner.token().start : scanner.index();
          }
        };
        return that;
      };
      Expression.initScanner = function(text, startIndex) {
        var isDigit, that, _index, _maxIndex, _text, _token;
        that = {};
        _text = text + " ";
        _maxIndex = text.length;
        _index = startIndex;
        _token = null;
        isDigit = function(c) {
          return "0123456789".indexOf(c) >= 0;
        };
        that.token = function() {
          return _token;
        };
        that.index = function() {
          return _index;
        };
        that.next = function() {
          var c, c1, c2, i;
          _token = null;
          while (_index < _maxIndex && " \t\r\n".indexOf(_text.charAt(_index)) >= 0) {
            _index += 1;
          }
          if (_index < _maxIndex) {
            c1 = _text.charAt(_index);
            c2 = _text.charAt(_index + 1);
            if (".!".indexOf(c1) >= 0) {
              if (c2 === "@") {
                _token = {
                  type: Expression.initScanner.PATH_OPERATOR,
                  value: c1 + c2,
                  start: _index,
                  end: _index + 2
                };
                return _index += 2;
              } else {
                _token = {
                  type: Expression.initScanner.PATH_OPERATOR,
                  value: c1,
                  start: _index,
                  end: _index + 1
                };
                return _index += 1;
              }
            } else if ("<>".indexOf(c1) >= 0) {
              if ((c2 === "=") || ("<>".indexOf(c2) >= 0 && c1 !== c2)) {
                _token = {
                  type: Expression.initScanner.OPERATOR,
                  value: c1 + c2,
                  start: _index,
                  end: _index + 2
                };
                return _index += 2;
              } else {
                _token = {
                  type: Expression.initScanner.OPERATOR,
                  value: c1,
                  start: _index,
                  end: _index + 1
                };
                return _index += 1;
              }
            } else if ("+-*/=".indexOf(c1) >= 0) {
              _token = {
                type: Expression.initScanner.OPERATOR,
                value: c1,
                start: _index,
                end: _index + 1
              };
              return _index += 1;
            } else if ("()".indexOf(c1) >= 0) {
              _token = {
                type: Expression.initScanner.DELIMITER,
                value: c1,
                start: _index,
                end: _index + 1
              };
              return _index += 1;
            } else if ("\"'".indexOf(c1) >= 0) {
              i = _index + 1;
              while (i < _maxIndex) {
                if (_text.charAt(i) === c1 && _text.charAt(i - 1) !== "\\") break;
                i += 1;
              }
              if (i < _maxIndex) {
                _token = {
                  type: Expression.initScanner.STRING,
                  value: _text.substring(_index + 1, i).replace(/\\'/g, "'").replace(/\\"/g, '"'),
                  start: _index,
                  end: i + 1
                };
                return _index = i + 1;
              } else {
                throw new Error("Unterminated string starting at " + String(_index));
              }
            } else if (isDigit(c1)) {
              i = _index;
              while (i < _maxIndex && isDigit(_text.charAt(i))) {
                i += 1;
              }
              if (i < _maxIndex && _text.charAt(i) === ".") {
                i += 1;
                while (i < _maxIndex && isDigit(_text.charAt(i))) {
                  i += 1;
                }
              }
              _token = {
                type: Expression.initScanner.NUMBER,
                value: parseFloat(_text.substring(_index, i)),
                start: _index,
                end: i
              };
              return _index = i;
            } else {
              i = _index;
              while (i < _maxIndex) {
                c = _text.charAt(i);
                if (!("(),.!@ \t".indexOf(c) < 0)) break;
                i += 1;
              }
              _token = {
                type: Expression.initScanner.IDENTIFIER,
                value: _text.substring(_index, i),
                start: _index,
                end: i
              };
              return _index = i;
            }
          }
        };
        that.next();
        return that;
      };
      Expression.initScanner.DELIMITER = 0;
      Expression.initScanner.NUMBER = 1;
      Expression.initScanner.STRING = 2;
      Expression.initScanner.IDENTIFIER = 3;
      Expression.initScanner.OPERATOR = 4;
      Expression.initScanner.PATH_OPERATOR = 5;
      Expression.functions = {};
      Expression.FunctionUtilities = {};
      return exports.registerSimpleMappingFunction = function(name, f, valueType) {
        return Expression.functions[name] = {
          f: function(args) {
            var arg, evalArg, set, _i, _len;
            set = MITHGrid.Data.initSet();
            evalArg = function(arg) {
              return arg.forEachValue(function(v) {
                var v2;
                v2 = f(v);
                if (v2 != null) return set.add(v2);
              });
            };
            for (_i = 0, _len = args.length; _i < _len; _i++) {
              arg = args[_i];
              evalArg(arg);
            }
            return Expression.initCollection(set, valueType);
          }
        };
      };
    });
    MITHGrid.namespace('Presentation', function(Presentation) {
      Presentation.initInstance = function(type, container, options) {
        var activeRenderingId, lensKeyExpression, lenses, renderings, that, _ref4;
        _ref4 = MITHGrid.normalizeArgs("MITHGrid.Presentation", type, container, options), type = _ref4[0], container = _ref4[1], options = _ref4[2];
        that = MITHGrid.initInstance(type, container, options);
        activeRenderingId = null;
        renderings = {};
        lenses = that.options.lenses || {};
        options = that.options;
        $(container).empty();
        lensKeyExpression = void 0;
        options.lensKey || (options.lensKey = ['.type']);
        that.getLens = function(id) {
          var key, keys;
          if (lensKeyExpression != null) {
            keys = lensKeyExpression.evaluate([id]);
            key = keys[0];
          }
          if ((key != null) && (lenses[key] != null)) {
            return {
              render: lenses[key]
            };
          }
        };
        that.addLens = function(key, lens) {
          return lenses[key] = lens;
        };
        that.removeLens = function(key) {
          return delete lenses[key];
        };
        that.hasLens = function(key) {
          return lenses[key] != null;
        };
        that.visitRenderings = function(cb) {
          var id, r;
          for (id in renderings) {
            r = renderings[id];
            if (false === cb(id, r)) return;
          }
        };
        that.renderingFor = function(id) {
          return renderings[id];
        };
        that.renderItems = function(model, items) {
          var f, n, step;
          if (!(lensKeyExpression != null)) {
            lensKeyExpression = model.prepare(options.lensKey);
          }
          n = items.length;
          step = n;
          if (step > 200) step = parseInt(Math.sqrt(step), 10) + 1;
          if (step < 1) step = 1;
          f = function(start) {
            var end, hasItem, i, id, rendering;
            if (start < n) {
              end = start + step;
              if (end > n) end = n;
              for (i = start; start <= end ? i < end : i > end; start <= end ? i++ : i--) {
                id = items[i];
                hasItem = model.contains(id);
                if (renderings[id] != null) {
                  if (!hasItem) {
                    if (activeRenderingId === id && (renderings[id].eventUnfocus != null)) {
                      renderings[id].eventUnfocus();
                    }
                    if (renderings[id].remove != null) renderings[id].remove();
                    delete renderings[id];
                  } else {
                    renderings[id].update(model.getItem(id));
                  }
                } else if (hasItem) {
                  rendering = that.render(container, model, id);
                  if (rendering != null) {
                    renderings[id] = rendering;
                    if (activeRenderingId === id && (rendering.eventFocus != null)) {
                      rendering.eventFocus();
                    }
                  }
                }
              }
              return setTimeout(function() {
                return f(end);
              }, 0);
            } else {
              return that.finishDisplayUpdate();
            }
          };
          that.startDisplayUpdate();
          return f(0);
        };
        that.render = function(c, m, i) {
          var lens;
          lens = that.getLens(i);
          if (lens != null) return lens.render(c, that, m, i);
        };
        that.eventModelChange = that.renderItems;
        that.startDisplayUpdate = function() {};
        that.finishDisplayUpdate = function() {};
        that.selfRender = function() {
          return that.renderItems(that.dataView, that.dataView.items());
        };
        that.eventFocusChange = function(id) {
          var rendering;
          if (activeRenderingId != null) {
            rendering = that.renderingFor(activeRenderingId);
          }
          if (activeRenderingId !== id) {
            if ((rendering != null) && (rendering.eventUnfocus != null)) {
              rendering.eventUnfocus();
            }
            if (id != null) {
              rendering = that.renderingFor(id);
              if ((rendering != null) && (rendering.eventFocus != null)) {
                rendering.eventFocus();
              }
            }
            activeRenderingId = id;
          }
          return activeRenderingId;
        };
        that.dataView = that.options.dataView;
        that.dataView.registerPresentation(that);
        return that;
      };
      return Presentation.namespace("SimpleText", function(SimpleText) {
        return SimpleText.initInstance = function(klass, container, options) {
          var that, _ref4;
          _ref4 = MITHGrid.normalizeArgs("MITHGrid.Presentation.SimpleText", klass, container, options), klass = _ref4[0], container = _ref4[1], options = _ref4[2];
          that = MITHGrid.Presentation.initInstance(klass, container, options);
          return that;
        };
      });
    });
    MITHGrid.namespace('Facet', function(Facet) {
      Facet.initInstance = function(klass, container, options) {
        var that;
        that = MITHGrid.initInstance(klass, container, options);
        options = that.options;
        that.selfRender = function() {};
        that.eventFilterItem = function(model, itemId) {
          return false;
        };
        that.eventModelChange = function(model, itemList) {};
        that.constructFacetFrame = function(container, options) {
          var dom;
          dom = {};
          $(container).addClass("mithgrid-facet");
          dom.header = $("<div class='header' />");
          if (options.onClearAllSelections != null) {
            dom.controls = $("<div class='control' title='Clear Selection'>");
            dom.counter = $("<span class='counter'></span>");
            dom.controls.append(dom.counter);
            dom.header.append(dom.controls);
          }
          dom.title = $("<span class='title'></span>");
          dom.title.text(options.facetLabel || "");
          dom.header.append(dom.title);
          dom.bodyFrame = $("<div class='body-frame'></div>");
          dom.body = $("<div class='body'></div>");
          dom.bodyFrame.append(dom.body);
          $(container).append(dom.header);
          $(container).append(dom.bodyFrame);
          if (options.onClearAllSelections != null) {
            dom.controls.bind("click", options.onClearAllSelections);
          }
          dom.setSelectionCount = function(count) {
            dom.counter.innerHTML = count;
            if (count > 0) {
              return dom.counter.show();
            } else {
              return dom.counter.hide();
            }
          };
          return dom;
        };
        options.dataView.registerFilter(that);
        return that;
      };
      Facet.namespace('TextSearch', function(TextSearch) {
        return TextSearch.initInstance = function(container, options) {
          var ex, parsed, that;
          that = Facet.initInstance("MITHGrid.Facet.TextSearch", container, options);
          options = that.options;
          if (options.expressions != null) {
            if (!$.isArray(options.expressions)) {
              options.expressions = [options.expressions];
              parsed = (function() {
                var _i, _len, _ref4, _results;
                _ref4 = options.expressions;
                _results = [];
                for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
                  ex = _ref4[_i];
                  _results.push(MITHGrid.Expression.initParser().parse(ex));
                }
                return _results;
              })();
            }
          }
          that.eventFilterItem = function(dataSource, id) {
            var ex, items, v, _i, _j, _len, _len2, _ref4;
            if ((that.text != null) && (options.expressions != null)) {
              for (_i = 0, _len = parsed.length; _i < _len; _i++) {
                ex = parsed[_i];
                items = ex.evaluateOnItem(id, dataSource);
                _ref4 = items.values.items();
                for (_j = 0, _len2 = _ref4.length; _j < _len2; _j++) {
                  v = _ref4[_j];
                  if (v.toLowerCase().indexOf(that.text) >= 0) return;
                }
              }
            }
            return false;
          };
          that.eventModelChange = function(dataView, itemList) {};
          that.selfRender = function() {
            var dom, inputElement;
            dom = that.constructFacetFrame(container, null, {
              facetLabel: options.facetLabel
            });
            $(container).addClass("mithgrid-facet-textsearch");
            inputElement = $("<input type='text'>");
            dom.body.append(inputElement);
            return inputElement.keyup(function() {
              that.text = $.trim(inputElement.val().toLowerCase());
              return that.events.onFilterChange.fire();
            });
          };
          return that;
        };
      });
      Facet.namespace('List', function(List) {
        return List.initInstance = function(container, options) {
          var ex, parsed, that;
          that = Facet.initInstance("MITHGrid.Facet.List", container, options);
          options = that.options;
          that.selections = [];
          if (options.expressions != null) {
            if (!$.isArray(options.expressions)) {
              options.expressions = [options.expressions];
              parsed = (function() {
                var _i, _len, _ref4, _results;
                _ref4 = options.expressions;
                _results = [];
                for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
                  ex = _ref4[_i];
                  _results.push(MITHGrid.Expression.initParser().parse(ex));
                }
                return _results;
              })();
            }
          }
          that.eventFilterItem = function(dataSource, id) {
            var ex, items, v, _i, _j, _len, _len2, _ref4;
            if ((that.text != null) && (options.expressions != null)) {
              for (_i = 0, _len = parsed.length; _i < _len; _i++) {
                ex = parsed[_i];
                items = ex.evaluateOnItem(id, dataSource);
                _ref4 = items.values.items();
                for (_j = 0, _len2 = _ref4.length; _j < _len2; _j++) {
                  v = _ref4[_j];
                  if (__indexOf.call(that.selections, v) >= 0) return;
                }
              }
            }
          };
          that.selfRender = function() {
            var dom;
            return dom = that.constructFacetFrame(container, null, {
              facetLabel: options.facetLabel,
              resizable: true
            });
          };
          return that;
        };
      });
      return Facet.namespace('Range', function(Range) {
        return Range.initInstance = function(container, options) {
          var that;
          that = Facet.initInstance("MITHGrid.Facet.Range", container, options);
          options = that.options;
          if (options.min == null) options.min = 0;
          if (options.max == null) options.max = 100;
          if (options.step == null) options.step = 1.0 / 30.0;
          that.selfRender = function() {
            var dom, inputElement;
            dom = that.constructFacetFrame(container, null, {
              facetLabel: options.facetLabel,
              resizable: false
            });
            inputElement = $("<input type='range'>");
            inputElement.attr({
              min: options.min,
              max: options.max,
              step: options.step
            });
            dom.body.append(inputElement);
            return inputElement.event(function() {
              that.value = inputElement.val();
              return that.events.onFilterChange.fire();
            });
          };
          return that;
        };
      });
    });
    MITHGrid.namespace('Controller', function(Controller) {
      return Controller.initInstance = function(klass, options) {
        var c, initDOMBinding, initRaphaelBinding, that, _ref4;
        _ref4 = MITHGrid.normalizeArgs("MITHGrid.Controller", klass, void 0, options), klass = _ref4[0], c = _ref4[1], options = _ref4[2];
        that = MITHGrid.initView(klass, options);
        options = that.options;
        options.selectors || (options.selectors = {});
        initDOMBinding = function(element) {
          var binding, bindingsCache;
          binding = MITHGrid.initView(options.bind);
          bindingsCache = {
            '': $(element)
          };
          binding.locate = function(internalSelector) {
            var el, selector;
            selector = options.selectors[internalSelector];
            if (selector != null) {
              if (selector === '') {
                el = $(element);
              } else {
                el = $(element).find(selector);
              }
              bindingsCache[selector] = el;
              return el;
            }
          };
          binding.fastLocate = function(internalSelector) {
            var selector;
            selector = options.selectors[internalSelector];
            if (selector != null) {
              if (bindingsCache[selector] != null) return bindingsCache[selector];
              return binding.locate(internalSelector);
            }
          };
          binding.refresh = function(listOfSelectors) {
            var internalSelector, selector, _i, _len;
            for (_i = 0, _len = listOfSelectors.length; _i < _len; _i++) {
              internalSelector = listOfSelectors[_i];
              selector = options.selectors[internalSelector];
              if (selector != null) {
                if (selector === '') {
                  bindingsCache[''] = $(element);
                } else {
                  bindingsCache[selector] = $(element).find(selector);
                }
              }
            }
          };
          binding.clearCache = function() {
            return bindingsCache = {
              '': $(element)
            };
          };
          return binding;
        };
        initRaphaelBinding = function(raphaelDrawing) {
          var binding, superBind, superFastLocate, superLocate, superRefresh;
          binding = initDOMBinding(raphaelDrawing.node);
          superLocate = binding.locate;
          superFastLocate = binding.fastLocate;
          superRefresh = binding.refresh;
          superBind = binding.bind;
          binding.locate = function(internalSelector) {
            if (internalSelector === 'raphael') {
              return raphaelDrawing;
            } else {
              return superLocate(internalSelector);
            }
          };
          binding.fastLocate = function(internalSelector) {
            if (internalSelector === 'raphael') {
              return raphaelDrawing;
            } else {
              return superFastLocate(internalSelector);
            }
          };
          binding.refresh = function(listOfSelectors) {
            var s;
            listOfSelectors = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = listOfSelectors.length; _i < _len; _i++) {
                s = listOfSelectors[_i];
                if (s !== 'raphael') _results.push(s);
              }
              return _results;
            })();
            return superRefresh(listOfSelectors);
          };
          return binding;
        };
        that.initBind = function(element) {
          if (typeof element === "string") {
            return initDOMBinding($(element));
          } else if (element.node != null) {
            return initRaphaelBinding(element);
          } else {
            return initDOMBinding(element);
          }
        };
        that.bind = function() {
          var args, binding, element;
          element = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
          binding = that.initBind(element);
          that.applyBindings.apply(that, [binding].concat(__slice.call(args)));
          return binding;
        };
        that.applyBindings = function() {
          var args, binding;
          binding = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        };
        return that;
      };
    });
    MITHGrid.namespace('Application', function(Application) {
      Application.initInstance = function(klass, container, options) {
        var configureInstance, onReady, that, _ref4;
        _ref4 = MITHGrid.normalizeArgs("MITHGrid.Application", klass, container, options), klass = _ref4[0], container = _ref4[1], options = _ref4[2];
        that = MITHGrid.initView(klass, container, options);
        onReady = [];
        that.presentation = {};
        that.facet = {};
        that.dataStore = {};
        that.dataView = {};
        that.controller = {};
        options = that.options;
        configureInstance = function() {
          var cName, cconfig, config, fName, fconfig, pName, pconfig, storeName, varName, viewConfig, viewName, _i, _len, _ref10, _ref11, _ref5, _ref6, _ref7, _ref8, _ref9, _results;
          if ((options != null ? options.variables : void 0) != null) {
            _ref5 = options.variables;
            for (varName in _ref5) {
              config = _ref5[varName];
              that.addVariable(varName, config);
            }
          }
          if ((options != null ? options.dataStores : void 0) != null) {
            _ref6 = options.dataStores;
            for (storeName in _ref6) {
              config = _ref6[storeName];
              that.addDataStore(storeName, config);
            }
          }
          if ((options != null ? options.dataViews : void 0) != null) {
            _ref7 = options.dataViews;
            for (viewName in _ref7) {
              viewConfig = _ref7[viewName];
              that.addDataView(viewName, viewConfig);
            }
          }
          if ((options != null ? options.controllers : void 0) != null) {
            _ref8 = options.controllers;
            for (cName in _ref8) {
              cconfig = _ref8[cName];
              that.addController(cName, cconfig);
            }
          }
          if ((options != null ? options.viewSetup : void 0) != null) {
            if ($.isFunction(options.viewSetup)) {
              that.ready(function() {
                return options.viewSetup($(container));
              });
            } else {
              that.ready(function() {
                return $(container).append(options.viewSetup);
              });
            }
          }
          if ((options != null ? options.facets : void 0) != null) {
            _ref9 = options.facets;
            for (fName in _ref9) {
              fconfig = _ref9[fName];
              that.addFacet(fName, fconfig);
            }
          }
          if ((options != null ? options.presentations : void 0) != null) {
            _ref10 = options.presentations;
            for (pName in _ref10) {
              pconfig = _ref10[pName];
              that.addPresentation(pName, pconfig);
            }
          }
          if ((options != null ? options.plugins : void 0) != null) {
            _ref11 = options.plugins;
            _results = [];
            for (_i = 0, _len = _ref11.length; _i < _len; _i++) {
              pconfig = _ref11[_i];
              _results.push(that.addPlugin(pconfig));
            }
            return _results;
          }
        };
        that.ready = function(fn) {
          return onReady.push(fn);
        };
        that.addVariable = function(varName, config) {
          var eventName, filter, getName, setName, validate, value, _ref5, _ref6;
          value = config["default"];
          config.is || (config.is = 'rw');
          if ((_ref5 = config.is) === 'rw' || _ref5 === 'w') {
            filter = config.filter;
            validate = config.validate;
            eventName = config.event || ('on' + varName + 'Change');
            setName = config.setter || ('set' + varName);
            that.events[eventName] = MITHGrid.initEventFirer();
            if (filter != null) {
              if (validate != null) {
                that[setName] = function(v) {
                  v = validate(filter(v));
                  if (value !== v) {
                    value = v;
                    return that.events[eventName].fire(value);
                  }
                };
              } else {
                that[setName] = function(v) {
                  v = filter(v);
                  if (value !== v) {
                    value = v;
                    return that.events[eventName].fire(value);
                  }
                };
              }
            } else {
              if (validate != null) {
                that[setName] = function(v) {
                  v = validate(v);
                  if (value !== v) {
                    value = v;
                    return that.events[eventName].fire(value);
                  }
                };
              } else {
                that[setName] = function(v) {
                  if (value !== v) {
                    value = v;
                    return that.events[eventName].fire(value);
                  }
                };
              }
            }
          }
          if ((_ref6 = config.is) === 'r' || _ref6 === 'rw') {
            getName = config.getter || ('get' + varName);
            return that[getName] = function() {
              return value;
            };
          }
        };
        that.addDataStore = function(storeName, config) {
          var prop, propOptions, store, type, typeInfo, _ref5, _ref6, _results;
          if (!(that.dataStore[storeName] != null)) {
            store = MITHGrid.Data.initStore();
            that.dataStore[storeName] = store;
            store.addType('Item');
            store.addProperty('label', {
              valueType: 'text'
            });
            store.addProperty('type', {
              valueType: 'text'
            });
            store.addProperty('id', {
              valueType: 'text'
            });
          } else {
            store = that.dataStore[storeName];
          }
          if ((config != null ? config.types : void 0) != null) {
            _ref5 = config.types;
            for (type in _ref5) {
              typeInfo = _ref5[type];
              store.addType(type);
            }
          }
          if ((config != null ? config.properties : void 0) != null) {
            _ref6 = config.properties;
            _results = [];
            for (prop in _ref6) {
              propOptions = _ref6[prop];
              _results.push(store.addProperty(prop, propOptions));
            }
            return _results;
          }
        };
        that.addDataView = function(viewName, viewConfig) {
          var initFn, k, v, view, viewOptions;
          if ((viewConfig.type != null) && (viewConfig.type.initInstance != null)) {
            initFn = viewConfig.type.initInstance;
          } else {
            initFn = MITHGrid.Data.View.initInstance;
          }
          viewOptions = {
            dataStore: that.dataStore[viewConfig.dataStore] || that.dataView[viewConfig.dataStore]
          };
          if (!(that.dataView[viewName] != null)) {
            for (k in viewConfig) {
              v = viewConfig[k];
              if (k !== "type" && !viewOptions[k]) viewOptions[k] = v;
            }
            view = initFn(viewOptions);
            return that.dataView[viewName] = view;
          }
        };
        that.addController = function(cName, cconfig) {
          var coptions;
          coptions = $.extend(true, {}, cconfig);
          return that.ready(function() {
            var controller;
            coptions.application = that;
            controller = cconfig.type.initController(coptions);
            return that.controller[cName] = controller;
          });
        };
        that.addFacet = function(fName, fconfig) {
          var foptions;
          foptions = $.extend(true, {}, fconfig);
          return that.ready(function() {
            var facet, fcontainer;
            fcontainer = $(container).find(fconfig.container);
            if ($.isArray(fcontainer)) fcontainer = fcontainer[0];
            foptions.dataView = that.dataView[fconfig.dataView];
            foptions.application = that;
            facet = fconfig.type.initFacet(fcontainer, foptions);
            that.facet[fName] = facet;
            return facet.selfRender();
          });
        };
        that.addPresentation = function(pName, pconfig) {
          var poptions;
          poptions = $.extend(true, {}, pconfig);
          return that.ready(function() {
            var cName, cconfig, coptions, pcontainer, presentation, _ref5;
            pcontainer = $(container).find(poptions.container);
            if ($.isArray(pcontainer)) pcontainer = pcontainer[0];
            poptions.dataView = that.dataView[pconfig.dataView];
            poptions.application = that;
            if (pconfig.controllers != null) {
              poptions.controllers = {};
              _ref5 = pconfig.controllers;
              for (cName in _ref5) {
                cconfig = _ref5[cName];
                if (typeof cconfig === "string") {
                  poptions.controllers[cName] = that.controller[cName];
                } else {
                  coptions = $.extend(true, {}, cconfig);
                  coptions.application = that;
                  poptions.controllers[cName] = cconfig.type.initController(coptions);
                }
              }
            }
            presentation = pconfig.type.initPresentation(pcontainer, poptions);
            that.presentation[pName] = presentation;
            return presentation.selfRender();
          });
        };
        that.addPlugin = function(pconf) {
          var pconfig;
          pconfig = $.extend(true, {}, pconf);
          pconfig.application = that;
          return that.ready(function() {
            var pcontainer, plugin, pname, prconfig, presentation, prop, propOptions, proptions, type, typeInfo, _ref5, _ref6, _ref7, _results;
            plugin = pconfig.type.initPlugin(pconfig);
            if (plugin != null) {
              if ((pconfig != null ? pconfig.dataView : void 0) != null) {
                plugin.dataView = that.dataView[pconfig.dataView];
                _ref5 = plugin.getTypes();
                for (type in _ref5) {
                  typeInfo = _ref5[type];
                  plugin.dataView.addType(type);
                }
                _ref6 = plugin.getProperties();
                for (prop in _ref6) {
                  propOptions = _ref6[prop];
                  plugin.dataView.addProperty(prop, propOptions);
                }
              }
              _ref7 = plugin.getPresentations();
              _results = [];
              for (pname in _ref7) {
                prconfig = _ref7[pname];
                proptions = $.extend(true, {}, prconfig.options);
                pcontainer = $(container).find(prconfig.container);
                if ($.isArray(pcontainer)) pcontainer = pcontainer[0];
                if ((prconfig != null ? prconfig.lenses : void 0) != null) {
                  proptions.lenses = prconfig.lenses;
                }
                if (prconfig.dataView != null) {
                  proptions.dataView = that.dataView[prconfig.dataView];
                } else if (pconfig.dataView != null) {
                  proptions.dataView = that.dataView[pconfig.dataView];
                }
                proptions.application = that;
                presentation = prconfig.type.initPresentation(pcontainer, proptions);
                plugin.presentation[pname] = presentation;
                _results.push(presentation.selfRender());
              }
              return _results;
            }
          });
        };
        configureInstance();
        that.run = function() {
          return $(document).ready(function() {
            var fn, _i, _len;
            for (_i = 0, _len = onReady.length; _i < _len; _i++) {
              fn = onReady[_i];
              fn();
            }
            onReady = [];
            return that.ready = function(fn) {
              return setTimeout(fn, 0);
            };
          });
        };
        return that;
      };
      return Application.initApp = Application.initInstance;
    });
    MITHGrid.namespace("Plugin", function(exports) {
      return exports.initPlugin = function(klass, options) {
        var readyFns, that;
        that = {
          options: options,
          presentation: {}
        };
        readyFns = [];
        that.getTypes = function() {
          if ((options != null ? options.types : void 0) != null) {
            return options.types;
          } else {
            return [];
          }
        };
        that.getProperties = function() {
          if ((options != null ? options.properties : void 0) != null) {
            return options.properties;
          } else {
            return [];
          }
        };
        that.getPresentations = function() {
          if ((options != null ? options.presentations : void 0) != null) {
            return options.presentations;
          } else {
            return [];
          }
        };
        that.ready = readyFns.push;
        that.eventReady = function(app) {
          var fn, _i, _len;
          for (_i = 0, _len = readyFns.length; _i < _len; _i++) {
            fn = readyFns[_i];
            fn(app);
          }
          readyFns = [];
          return that.ready = function(fn) {
            return fn(app);
          };
        };
        return that;
      };
    });
    MITHGrid.initView = MITHGrid.initInstance;
    MITHGrid.Data.initSet = MITHGrid.Data.Set.initInstance;
    MITHGrid.Data.initType = MITHGrid.Data.Type.initInstance;
    MITHGrid.Data.initProperty = MITHGrid.Data.Property.initInstance;
    MITHGrid.Data.initStore = MITHGrid.Data.Store.initInstance;
    MITHGrid.Data.initView = MITHGrid.Data.View.initInstance;
    MITHGrid.Controller.initController = MITHGrid.Controller.initInstance;
    MITHGrid.Controller.initRaphaelController = MITHGrid.Controller.initController;
    MITHGrid.Presentation.initPresentation = MITHGrid.Presentation.initInstance;
    return MITHGrid.Presentation.SimpleText.initPresentation = MITHGrid.Presentation.SimpleText.initInstance;
  })(jQuery, MITHGrid);

  MITHGrid.defaults("MITHGrid.Data.Store", {
    events: {
      onModelChange: null,
      onBeforeLoading: null,
      onAfterLoading: null,
      onBeforeUpdating: null,
      onAfterUpdating: null
    }
  });

  MITHGrid.defaults("MITHGrid.Data.View", {
    events: {
      onModelChange: null,
      onFilterItem: "preventable"
    }
  });

  MITHGrid.defaults("MITHGrid.Data.SubSet", {
    events: {
      onModelChange: null
    }
  });

  MITHGrid.defaults("MITHGrid.Data.Pager", {
    events: {
      onModelChange: null
    }
  });

  MITHGrid.defaults("MITHGrid.Data.RangePager", {
    events: {
      onModelChange: null
    }
  });

  MITHGrid.defaults("MITHGrid.Data.ListPager", {
    events: {
      onModelChange: null
    }
  });

  MITHGrid.defaults("MITHGrid.Facet", {
    events: {
      onFilterChange: null
    }
  });

  MITHGrid.defaults("MITHGrid.Facet.TextSearch", {
    facetLabel: "Search",
    expressions: [".label"]
  });

}).call(this);
