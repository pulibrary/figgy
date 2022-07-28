(() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));
  var __toBinary = /* @__PURE__ */ (() => {
    var table = new Uint8Array(128);
    for (var i = 0; i < 64; i++)
      table[i < 26 ? i + 65 : i < 52 ? i + 71 : i < 62 ? i - 4 : i * 4 - 205] = i;
    return (base64) => {
      var n = base64.length, bytes = new Uint8Array((n - (base64[n - 1] == "=") - (base64[n - 2] == "=")) * 3 / 4 | 0);
      for (var i2 = 0, j = 0; i2 < n; ) {
        var c0 = table[base64.charCodeAt(i2++)], c1 = table[base64.charCodeAt(i2++)];
        var c2 = table[base64.charCodeAt(i2++)], c3 = table[base64.charCodeAt(i2++)];
        bytes[j++] = c0 << 2 | c1 >> 4;
        bytes[j++] = c1 << 4 | c2 >> 2;
        bytes[j++] = c2 << 6 | c3;
      }
      return bytes;
    };
  })();

  // node_modules/leaflet/dist/leaflet-src.js
  var require_leaflet_src = __commonJS({
    "node_modules/leaflet/dist/leaflet-src.js"(exports, module) {
      (function(global, factory) {
        typeof exports === "object" && typeof module !== "undefined" ? factory(exports) : typeof define === "function" && define.amd ? define(["exports"], factory) : (global = typeof globalThis !== "undefined" ? globalThis : global || self, factory(global.leaflet = {}));
      })(exports, function(exports2) {
        "use strict";
        var version = "1.8.0";
        function extend(dest) {
          var i, j, len, src;
          for (j = 1, len = arguments.length; j < len; j++) {
            src = arguments[j];
            for (i in src) {
              dest[i] = src[i];
            }
          }
          return dest;
        }
        var create$2 = Object.create || function() {
          function F() {
          }
          return function(proto) {
            F.prototype = proto;
            return new F();
          };
        }();
        function bind(fn, obj) {
          var slice = Array.prototype.slice;
          if (fn.bind) {
            return fn.bind.apply(fn, slice.call(arguments, 1));
          }
          var args = slice.call(arguments, 2);
          return function() {
            return fn.apply(obj, args.length ? args.concat(slice.call(arguments)) : arguments);
          };
        }
        var lastId = 0;
        function stamp(obj) {
          if (!("_leaflet_id" in obj)) {
            obj["_leaflet_id"] = ++lastId;
          }
          return obj._leaflet_id;
        }
        function throttle(fn, time, context) {
          var lock, args, wrapperFn, later;
          later = function() {
            lock = false;
            if (args) {
              wrapperFn.apply(context, args);
              args = false;
            }
          };
          wrapperFn = function() {
            if (lock) {
              args = arguments;
            } else {
              fn.apply(context, arguments);
              setTimeout(later, time);
              lock = true;
            }
          };
          return wrapperFn;
        }
        function wrapNum(x, range, includeMax) {
          var max = range[1], min = range[0], d = max - min;
          return x === max && includeMax ? x : ((x - min) % d + d) % d + min;
        }
        function falseFn() {
          return false;
        }
        function formatNum(num, precision) {
          if (precision === false) {
            return num;
          }
          var pow = Math.pow(10, precision === void 0 ? 6 : precision);
          return Math.round(num * pow) / pow;
        }
        function trim(str) {
          return str.trim ? str.trim() : str.replace(/^\s+|\s+$/g, "");
        }
        function splitWords(str) {
          return trim(str).split(/\s+/);
        }
        function setOptions(obj, options) {
          if (!Object.prototype.hasOwnProperty.call(obj, "options")) {
            obj.options = obj.options ? create$2(obj.options) : {};
          }
          for (var i in options) {
            obj.options[i] = options[i];
          }
          return obj.options;
        }
        function getParamString(obj, existingUrl, uppercase) {
          var params = [];
          for (var i in obj) {
            params.push(encodeURIComponent(uppercase ? i.toUpperCase() : i) + "=" + encodeURIComponent(obj[i]));
          }
          return (!existingUrl || existingUrl.indexOf("?") === -1 ? "?" : "&") + params.join("&");
        }
        var templateRe = /\{ *([\w_ -]+) *\}/g;
        function template(str, data) {
          return str.replace(templateRe, function(str2, key) {
            var value = data[key];
            if (value === void 0) {
              throw new Error("No value provided for variable " + str2);
            } else if (typeof value === "function") {
              value = value(data);
            }
            return value;
          });
        }
        var isArray = Array.isArray || function(obj) {
          return Object.prototype.toString.call(obj) === "[object Array]";
        };
        function indexOf(array, el) {
          for (var i = 0; i < array.length; i++) {
            if (array[i] === el) {
              return i;
            }
          }
          return -1;
        }
        var emptyImageUrl = "data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=";
        function getPrefixed(name) {
          return window["webkit" + name] || window["moz" + name] || window["ms" + name];
        }
        var lastTime = 0;
        function timeoutDefer(fn) {
          var time = +new Date(), timeToCall = Math.max(0, 16 - (time - lastTime));
          lastTime = time + timeToCall;
          return window.setTimeout(fn, timeToCall);
        }
        var requestFn = window.requestAnimationFrame || getPrefixed("RequestAnimationFrame") || timeoutDefer;
        var cancelFn = window.cancelAnimationFrame || getPrefixed("CancelAnimationFrame") || getPrefixed("CancelRequestAnimationFrame") || function(id) {
          window.clearTimeout(id);
        };
        function requestAnimFrame(fn, context, immediate) {
          if (immediate && requestFn === timeoutDefer) {
            fn.call(context);
          } else {
            return requestFn.call(window, bind(fn, context));
          }
        }
        function cancelAnimFrame(id) {
          if (id) {
            cancelFn.call(window, id);
          }
        }
        var Util = {
          __proto__: null,
          extend,
          create: create$2,
          bind,
          get lastId() {
            return lastId;
          },
          stamp,
          throttle,
          wrapNum,
          falseFn,
          formatNum,
          trim,
          splitWords,
          setOptions,
          getParamString,
          template,
          isArray,
          indexOf,
          emptyImageUrl,
          requestFn,
          cancelFn,
          requestAnimFrame,
          cancelAnimFrame
        };
        function Class() {
        }
        Class.extend = function(props) {
          var NewClass = function() {
            setOptions(this);
            if (this.initialize) {
              this.initialize.apply(this, arguments);
            }
            this.callInitHooks();
          };
          var parentProto = NewClass.__super__ = this.prototype;
          var proto = create$2(parentProto);
          proto.constructor = NewClass;
          NewClass.prototype = proto;
          for (var i in this) {
            if (Object.prototype.hasOwnProperty.call(this, i) && i !== "prototype" && i !== "__super__") {
              NewClass[i] = this[i];
            }
          }
          if (props.statics) {
            extend(NewClass, props.statics);
          }
          if (props.includes) {
            checkDeprecatedMixinEvents(props.includes);
            extend.apply(null, [proto].concat(props.includes));
          }
          extend(proto, props);
          delete proto.statics;
          delete proto.includes;
          if (proto.options) {
            proto.options = parentProto.options ? create$2(parentProto.options) : {};
            extend(proto.options, props.options);
          }
          proto._initHooks = [];
          proto.callInitHooks = function() {
            if (this._initHooksCalled) {
              return;
            }
            if (parentProto.callInitHooks) {
              parentProto.callInitHooks.call(this);
            }
            this._initHooksCalled = true;
            for (var i2 = 0, len = proto._initHooks.length; i2 < len; i2++) {
              proto._initHooks[i2].call(this);
            }
          };
          return NewClass;
        };
        Class.include = function(props) {
          var parentOptions = this.prototype.options;
          extend(this.prototype, props);
          if (props.options) {
            this.prototype.options = parentOptions;
            this.mergeOptions(props.options);
          }
          return this;
        };
        Class.mergeOptions = function(options) {
          extend(this.prototype.options, options);
          return this;
        };
        Class.addInitHook = function(fn) {
          var args = Array.prototype.slice.call(arguments, 1);
          var init = typeof fn === "function" ? fn : function() {
            this[fn].apply(this, args);
          };
          this.prototype._initHooks = this.prototype._initHooks || [];
          this.prototype._initHooks.push(init);
          return this;
        };
        function checkDeprecatedMixinEvents(includes) {
          if (typeof L === "undefined" || !L || !L.Mixin) {
            return;
          }
          includes = isArray(includes) ? includes : [includes];
          for (var i = 0; i < includes.length; i++) {
            if (includes[i] === L.Mixin.Events) {
              console.warn("Deprecated include of L.Mixin.Events: this property will be removed in future releases, please inherit from L.Evented instead.", new Error().stack);
            }
          }
        }
        var Events = {
          on: function(types, fn, context) {
            if (typeof types === "object") {
              for (var type in types) {
                this._on(type, types[type], fn);
              }
            } else {
              types = splitWords(types);
              for (var i = 0, len = types.length; i < len; i++) {
                this._on(types[i], fn, context);
              }
            }
            return this;
          },
          off: function(types, fn, context) {
            if (!arguments.length) {
              delete this._events;
            } else if (typeof types === "object") {
              for (var type in types) {
                this._off(type, types[type], fn);
              }
            } else {
              types = splitWords(types);
              var removeAll = arguments.length === 1;
              for (var i = 0, len = types.length; i < len; i++) {
                if (removeAll) {
                  this._off(types[i]);
                } else {
                  this._off(types[i], fn, context);
                }
              }
            }
            return this;
          },
          _on: function(type, fn, context) {
            if (typeof fn !== "function") {
              console.warn("wrong listener type: " + typeof fn);
              return;
            }
            this._events = this._events || {};
            var typeListeners = this._events[type];
            if (!typeListeners) {
              typeListeners = [];
              this._events[type] = typeListeners;
            }
            if (context === this) {
              context = void 0;
            }
            var newListener = { fn, ctx: context }, listeners = typeListeners;
            for (var i = 0, len = listeners.length; i < len; i++) {
              if (listeners[i].fn === fn && listeners[i].ctx === context) {
                return;
              }
            }
            listeners.push(newListener);
          },
          _off: function(type, fn, context) {
            var listeners, i, len;
            if (!this._events) {
              return;
            }
            listeners = this._events[type];
            if (!listeners) {
              return;
            }
            if (arguments.length === 1) {
              if (this._firingCount) {
                for (i = 0, len = listeners.length; i < len; i++) {
                  listeners[i].fn = falseFn;
                }
              }
              delete this._events[type];
              return;
            }
            if (context === this) {
              context = void 0;
            }
            if (typeof fn !== "function") {
              console.warn("wrong listener type: " + typeof fn);
              return;
            }
            for (i = 0, len = listeners.length; i < len; i++) {
              var l = listeners[i];
              if (l.ctx !== context) {
                continue;
              }
              if (l.fn === fn) {
                if (this._firingCount) {
                  l.fn = falseFn;
                  this._events[type] = listeners = listeners.slice();
                }
                listeners.splice(i, 1);
                return;
              }
            }
            console.warn("listener not found");
          },
          fire: function(type, data, propagate) {
            if (!this.listens(type, propagate)) {
              return this;
            }
            var event = extend({}, data, {
              type,
              target: this,
              sourceTarget: data && data.sourceTarget || this
            });
            if (this._events) {
              var listeners = this._events[type];
              if (listeners) {
                this._firingCount = this._firingCount + 1 || 1;
                for (var i = 0, len = listeners.length; i < len; i++) {
                  var l = listeners[i];
                  l.fn.call(l.ctx || this, event);
                }
                this._firingCount--;
              }
            }
            if (propagate) {
              this._propagateEvent(event);
            }
            return this;
          },
          listens: function(type, propagate) {
            if (typeof type !== "string") {
              console.warn('"string" type argument expected');
            }
            var listeners = this._events && this._events[type];
            if (listeners && listeners.length) {
              return true;
            }
            if (propagate) {
              for (var id in this._eventParents) {
                if (this._eventParents[id].listens(type, propagate)) {
                  return true;
                }
              }
            }
            return false;
          },
          once: function(types, fn, context) {
            if (typeof types === "object") {
              for (var type in types) {
                this.once(type, types[type], fn);
              }
              return this;
            }
            var handler = bind(function() {
              this.off(types, fn, context).off(types, handler, context);
            }, this);
            return this.on(types, fn, context).on(types, handler, context);
          },
          addEventParent: function(obj) {
            this._eventParents = this._eventParents || {};
            this._eventParents[stamp(obj)] = obj;
            return this;
          },
          removeEventParent: function(obj) {
            if (this._eventParents) {
              delete this._eventParents[stamp(obj)];
            }
            return this;
          },
          _propagateEvent: function(e) {
            for (var id in this._eventParents) {
              this._eventParents[id].fire(e.type, extend({
                layer: e.target,
                propagatedFrom: e.target
              }, e), true);
            }
          }
        };
        Events.addEventListener = Events.on;
        Events.removeEventListener = Events.clearAllEventListeners = Events.off;
        Events.addOneTimeEventListener = Events.once;
        Events.fireEvent = Events.fire;
        Events.hasEventListeners = Events.listens;
        var Evented = Class.extend(Events);
        function Point(x, y, round) {
          this.x = round ? Math.round(x) : x;
          this.y = round ? Math.round(y) : y;
        }
        var trunc = Math.trunc || function(v) {
          return v > 0 ? Math.floor(v) : Math.ceil(v);
        };
        Point.prototype = {
          clone: function() {
            return new Point(this.x, this.y);
          },
          add: function(point) {
            return this.clone()._add(toPoint(point));
          },
          _add: function(point) {
            this.x += point.x;
            this.y += point.y;
            return this;
          },
          subtract: function(point) {
            return this.clone()._subtract(toPoint(point));
          },
          _subtract: function(point) {
            this.x -= point.x;
            this.y -= point.y;
            return this;
          },
          divideBy: function(num) {
            return this.clone()._divideBy(num);
          },
          _divideBy: function(num) {
            this.x /= num;
            this.y /= num;
            return this;
          },
          multiplyBy: function(num) {
            return this.clone()._multiplyBy(num);
          },
          _multiplyBy: function(num) {
            this.x *= num;
            this.y *= num;
            return this;
          },
          scaleBy: function(point) {
            return new Point(this.x * point.x, this.y * point.y);
          },
          unscaleBy: function(point) {
            return new Point(this.x / point.x, this.y / point.y);
          },
          round: function() {
            return this.clone()._round();
          },
          _round: function() {
            this.x = Math.round(this.x);
            this.y = Math.round(this.y);
            return this;
          },
          floor: function() {
            return this.clone()._floor();
          },
          _floor: function() {
            this.x = Math.floor(this.x);
            this.y = Math.floor(this.y);
            return this;
          },
          ceil: function() {
            return this.clone()._ceil();
          },
          _ceil: function() {
            this.x = Math.ceil(this.x);
            this.y = Math.ceil(this.y);
            return this;
          },
          trunc: function() {
            return this.clone()._trunc();
          },
          _trunc: function() {
            this.x = trunc(this.x);
            this.y = trunc(this.y);
            return this;
          },
          distanceTo: function(point) {
            point = toPoint(point);
            var x = point.x - this.x, y = point.y - this.y;
            return Math.sqrt(x * x + y * y);
          },
          equals: function(point) {
            point = toPoint(point);
            return point.x === this.x && point.y === this.y;
          },
          contains: function(point) {
            point = toPoint(point);
            return Math.abs(point.x) <= Math.abs(this.x) && Math.abs(point.y) <= Math.abs(this.y);
          },
          toString: function() {
            return "Point(" + formatNum(this.x) + ", " + formatNum(this.y) + ")";
          }
        };
        function toPoint(x, y, round) {
          if (x instanceof Point) {
            return x;
          }
          if (isArray(x)) {
            return new Point(x[0], x[1]);
          }
          if (x === void 0 || x === null) {
            return x;
          }
          if (typeof x === "object" && "x" in x && "y" in x) {
            return new Point(x.x, x.y);
          }
          return new Point(x, y, round);
        }
        function Bounds(a, b) {
          if (!a) {
            return;
          }
          var points = b ? [a, b] : a;
          for (var i = 0, len = points.length; i < len; i++) {
            this.extend(points[i]);
          }
        }
        Bounds.prototype = {
          extend: function(point) {
            point = toPoint(point);
            if (!this.min && !this.max) {
              this.min = point.clone();
              this.max = point.clone();
            } else {
              this.min.x = Math.min(point.x, this.min.x);
              this.max.x = Math.max(point.x, this.max.x);
              this.min.y = Math.min(point.y, this.min.y);
              this.max.y = Math.max(point.y, this.max.y);
            }
            return this;
          },
          getCenter: function(round) {
            return new Point(
              (this.min.x + this.max.x) / 2,
              (this.min.y + this.max.y) / 2,
              round
            );
          },
          getBottomLeft: function() {
            return new Point(this.min.x, this.max.y);
          },
          getTopRight: function() {
            return new Point(this.max.x, this.min.y);
          },
          getTopLeft: function() {
            return this.min;
          },
          getBottomRight: function() {
            return this.max;
          },
          getSize: function() {
            return this.max.subtract(this.min);
          },
          contains: function(obj) {
            var min, max;
            if (typeof obj[0] === "number" || obj instanceof Point) {
              obj = toPoint(obj);
            } else {
              obj = toBounds(obj);
            }
            if (obj instanceof Bounds) {
              min = obj.min;
              max = obj.max;
            } else {
              min = max = obj;
            }
            return min.x >= this.min.x && max.x <= this.max.x && min.y >= this.min.y && max.y <= this.max.y;
          },
          intersects: function(bounds) {
            bounds = toBounds(bounds);
            var min = this.min, max = this.max, min2 = bounds.min, max2 = bounds.max, xIntersects = max2.x >= min.x && min2.x <= max.x, yIntersects = max2.y >= min.y && min2.y <= max.y;
            return xIntersects && yIntersects;
          },
          overlaps: function(bounds) {
            bounds = toBounds(bounds);
            var min = this.min, max = this.max, min2 = bounds.min, max2 = bounds.max, xOverlaps = max2.x > min.x && min2.x < max.x, yOverlaps = max2.y > min.y && min2.y < max.y;
            return xOverlaps && yOverlaps;
          },
          isValid: function() {
            return !!(this.min && this.max);
          }
        };
        function toBounds(a, b) {
          if (!a || a instanceof Bounds) {
            return a;
          }
          return new Bounds(a, b);
        }
        function LatLngBounds(corner1, corner2) {
          if (!corner1) {
            return;
          }
          var latlngs = corner2 ? [corner1, corner2] : corner1;
          for (var i = 0, len = latlngs.length; i < len; i++) {
            this.extend(latlngs[i]);
          }
        }
        LatLngBounds.prototype = {
          extend: function(obj) {
            var sw = this._southWest, ne = this._northEast, sw2, ne2;
            if (obj instanceof LatLng) {
              sw2 = obj;
              ne2 = obj;
            } else if (obj instanceof LatLngBounds) {
              sw2 = obj._southWest;
              ne2 = obj._northEast;
              if (!sw2 || !ne2) {
                return this;
              }
            } else {
              return obj ? this.extend(toLatLng(obj) || toLatLngBounds(obj)) : this;
            }
            if (!sw && !ne) {
              this._southWest = new LatLng(sw2.lat, sw2.lng);
              this._northEast = new LatLng(ne2.lat, ne2.lng);
            } else {
              sw.lat = Math.min(sw2.lat, sw.lat);
              sw.lng = Math.min(sw2.lng, sw.lng);
              ne.lat = Math.max(ne2.lat, ne.lat);
              ne.lng = Math.max(ne2.lng, ne.lng);
            }
            return this;
          },
          pad: function(bufferRatio) {
            var sw = this._southWest, ne = this._northEast, heightBuffer = Math.abs(sw.lat - ne.lat) * bufferRatio, widthBuffer = Math.abs(sw.lng - ne.lng) * bufferRatio;
            return new LatLngBounds(
              new LatLng(sw.lat - heightBuffer, sw.lng - widthBuffer),
              new LatLng(ne.lat + heightBuffer, ne.lng + widthBuffer)
            );
          },
          getCenter: function() {
            return new LatLng(
              (this._southWest.lat + this._northEast.lat) / 2,
              (this._southWest.lng + this._northEast.lng) / 2
            );
          },
          getSouthWest: function() {
            return this._southWest;
          },
          getNorthEast: function() {
            return this._northEast;
          },
          getNorthWest: function() {
            return new LatLng(this.getNorth(), this.getWest());
          },
          getSouthEast: function() {
            return new LatLng(this.getSouth(), this.getEast());
          },
          getWest: function() {
            return this._southWest.lng;
          },
          getSouth: function() {
            return this._southWest.lat;
          },
          getEast: function() {
            return this._northEast.lng;
          },
          getNorth: function() {
            return this._northEast.lat;
          },
          contains: function(obj) {
            if (typeof obj[0] === "number" || obj instanceof LatLng || "lat" in obj) {
              obj = toLatLng(obj);
            } else {
              obj = toLatLngBounds(obj);
            }
            var sw = this._southWest, ne = this._northEast, sw2, ne2;
            if (obj instanceof LatLngBounds) {
              sw2 = obj.getSouthWest();
              ne2 = obj.getNorthEast();
            } else {
              sw2 = ne2 = obj;
            }
            return sw2.lat >= sw.lat && ne2.lat <= ne.lat && sw2.lng >= sw.lng && ne2.lng <= ne.lng;
          },
          intersects: function(bounds) {
            bounds = toLatLngBounds(bounds);
            var sw = this._southWest, ne = this._northEast, sw2 = bounds.getSouthWest(), ne2 = bounds.getNorthEast(), latIntersects = ne2.lat >= sw.lat && sw2.lat <= ne.lat, lngIntersects = ne2.lng >= sw.lng && sw2.lng <= ne.lng;
            return latIntersects && lngIntersects;
          },
          overlaps: function(bounds) {
            bounds = toLatLngBounds(bounds);
            var sw = this._southWest, ne = this._northEast, sw2 = bounds.getSouthWest(), ne2 = bounds.getNorthEast(), latOverlaps = ne2.lat > sw.lat && sw2.lat < ne.lat, lngOverlaps = ne2.lng > sw.lng && sw2.lng < ne.lng;
            return latOverlaps && lngOverlaps;
          },
          toBBoxString: function() {
            return [this.getWest(), this.getSouth(), this.getEast(), this.getNorth()].join(",");
          },
          equals: function(bounds, maxMargin) {
            if (!bounds) {
              return false;
            }
            bounds = toLatLngBounds(bounds);
            return this._southWest.equals(bounds.getSouthWest(), maxMargin) && this._northEast.equals(bounds.getNorthEast(), maxMargin);
          },
          isValid: function() {
            return !!(this._southWest && this._northEast);
          }
        };
        function toLatLngBounds(a, b) {
          if (a instanceof LatLngBounds) {
            return a;
          }
          return new LatLngBounds(a, b);
        }
        function LatLng(lat, lng, alt) {
          if (isNaN(lat) || isNaN(lng)) {
            throw new Error("Invalid LatLng object: (" + lat + ", " + lng + ")");
          }
          this.lat = +lat;
          this.lng = +lng;
          if (alt !== void 0) {
            this.alt = +alt;
          }
        }
        LatLng.prototype = {
          equals: function(obj, maxMargin) {
            if (!obj) {
              return false;
            }
            obj = toLatLng(obj);
            var margin = Math.max(
              Math.abs(this.lat - obj.lat),
              Math.abs(this.lng - obj.lng)
            );
            return margin <= (maxMargin === void 0 ? 1e-9 : maxMargin);
          },
          toString: function(precision) {
            return "LatLng(" + formatNum(this.lat, precision) + ", " + formatNum(this.lng, precision) + ")";
          },
          distanceTo: function(other) {
            return Earth.distance(this, toLatLng(other));
          },
          wrap: function() {
            return Earth.wrapLatLng(this);
          },
          toBounds: function(sizeInMeters) {
            var latAccuracy = 180 * sizeInMeters / 40075017, lngAccuracy = latAccuracy / Math.cos(Math.PI / 180 * this.lat);
            return toLatLngBounds(
              [this.lat - latAccuracy, this.lng - lngAccuracy],
              [this.lat + latAccuracy, this.lng + lngAccuracy]
            );
          },
          clone: function() {
            return new LatLng(this.lat, this.lng, this.alt);
          }
        };
        function toLatLng(a, b, c) {
          if (a instanceof LatLng) {
            return a;
          }
          if (isArray(a) && typeof a[0] !== "object") {
            if (a.length === 3) {
              return new LatLng(a[0], a[1], a[2]);
            }
            if (a.length === 2) {
              return new LatLng(a[0], a[1]);
            }
            return null;
          }
          if (a === void 0 || a === null) {
            return a;
          }
          if (typeof a === "object" && "lat" in a) {
            return new LatLng(a.lat, "lng" in a ? a.lng : a.lon, a.alt);
          }
          if (b === void 0) {
            return null;
          }
          return new LatLng(a, b, c);
        }
        var CRS = {
          latLngToPoint: function(latlng, zoom2) {
            var projectedPoint = this.projection.project(latlng), scale2 = this.scale(zoom2);
            return this.transformation._transform(projectedPoint, scale2);
          },
          pointToLatLng: function(point, zoom2) {
            var scale2 = this.scale(zoom2), untransformedPoint = this.transformation.untransform(point, scale2);
            return this.projection.unproject(untransformedPoint);
          },
          project: function(latlng) {
            return this.projection.project(latlng);
          },
          unproject: function(point) {
            return this.projection.unproject(point);
          },
          scale: function(zoom2) {
            return 256 * Math.pow(2, zoom2);
          },
          zoom: function(scale2) {
            return Math.log(scale2 / 256) / Math.LN2;
          },
          getProjectedBounds: function(zoom2) {
            if (this.infinite) {
              return null;
            }
            var b = this.projection.bounds, s = this.scale(zoom2), min = this.transformation.transform(b.min, s), max = this.transformation.transform(b.max, s);
            return new Bounds(min, max);
          },
          infinite: false,
          wrapLatLng: function(latlng) {
            var lng = this.wrapLng ? wrapNum(latlng.lng, this.wrapLng, true) : latlng.lng, lat = this.wrapLat ? wrapNum(latlng.lat, this.wrapLat, true) : latlng.lat, alt = latlng.alt;
            return new LatLng(lat, lng, alt);
          },
          wrapLatLngBounds: function(bounds) {
            var center = bounds.getCenter(), newCenter = this.wrapLatLng(center), latShift = center.lat - newCenter.lat, lngShift = center.lng - newCenter.lng;
            if (latShift === 0 && lngShift === 0) {
              return bounds;
            }
            var sw = bounds.getSouthWest(), ne = bounds.getNorthEast(), newSw = new LatLng(sw.lat - latShift, sw.lng - lngShift), newNe = new LatLng(ne.lat - latShift, ne.lng - lngShift);
            return new LatLngBounds(newSw, newNe);
          }
        };
        var Earth = extend({}, CRS, {
          wrapLng: [-180, 180],
          R: 6371e3,
          distance: function(latlng1, latlng2) {
            var rad = Math.PI / 180, lat1 = latlng1.lat * rad, lat2 = latlng2.lat * rad, sinDLat = Math.sin((latlng2.lat - latlng1.lat) * rad / 2), sinDLon = Math.sin((latlng2.lng - latlng1.lng) * rad / 2), a = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon, c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return this.R * c;
          }
        });
        var earthRadius = 6378137;
        var SphericalMercator = {
          R: earthRadius,
          MAX_LATITUDE: 85.0511287798,
          project: function(latlng) {
            var d = Math.PI / 180, max = this.MAX_LATITUDE, lat = Math.max(Math.min(max, latlng.lat), -max), sin = Math.sin(lat * d);
            return new Point(
              this.R * latlng.lng * d,
              this.R * Math.log((1 + sin) / (1 - sin)) / 2
            );
          },
          unproject: function(point) {
            var d = 180 / Math.PI;
            return new LatLng(
              (2 * Math.atan(Math.exp(point.y / this.R)) - Math.PI / 2) * d,
              point.x * d / this.R
            );
          },
          bounds: function() {
            var d = earthRadius * Math.PI;
            return new Bounds([-d, -d], [d, d]);
          }()
        };
        function Transformation(a, b, c, d) {
          if (isArray(a)) {
            this._a = a[0];
            this._b = a[1];
            this._c = a[2];
            this._d = a[3];
            return;
          }
          this._a = a;
          this._b = b;
          this._c = c;
          this._d = d;
        }
        Transformation.prototype = {
          transform: function(point, scale2) {
            return this._transform(point.clone(), scale2);
          },
          _transform: function(point, scale2) {
            scale2 = scale2 || 1;
            point.x = scale2 * (this._a * point.x + this._b);
            point.y = scale2 * (this._c * point.y + this._d);
            return point;
          },
          untransform: function(point, scale2) {
            scale2 = scale2 || 1;
            return new Point(
              (point.x / scale2 - this._b) / this._a,
              (point.y / scale2 - this._d) / this._c
            );
          }
        };
        function toTransformation(a, b, c, d) {
          return new Transformation(a, b, c, d);
        }
        var EPSG3857 = extend({}, Earth, {
          code: "EPSG:3857",
          projection: SphericalMercator,
          transformation: function() {
            var scale2 = 0.5 / (Math.PI * SphericalMercator.R);
            return toTransformation(scale2, 0.5, -scale2, 0.5);
          }()
        });
        var EPSG900913 = extend({}, EPSG3857, {
          code: "EPSG:900913"
        });
        function svgCreate(name) {
          return document.createElementNS("http://www.w3.org/2000/svg", name);
        }
        function pointsToPath(rings, closed) {
          var str = "", i, j, len, len2, points, p;
          for (i = 0, len = rings.length; i < len; i++) {
            points = rings[i];
            for (j = 0, len2 = points.length; j < len2; j++) {
              p = points[j];
              str += (j ? "L" : "M") + p.x + " " + p.y;
            }
            str += closed ? Browser.svg ? "z" : "x" : "";
          }
          return str || "M0 0";
        }
        var style = document.documentElement.style;
        var ie = "ActiveXObject" in window;
        var ielt9 = ie && !document.addEventListener;
        var edge = "msLaunchUri" in navigator && !("documentMode" in document);
        var webkit = userAgentContains("webkit");
        var android = userAgentContains("android");
        var android23 = userAgentContains("android 2") || userAgentContains("android 3");
        var webkitVer = parseInt(/WebKit\/([0-9]+)|$/.exec(navigator.userAgent)[1], 10);
        var androidStock = android && userAgentContains("Google") && webkitVer < 537 && !("AudioNode" in window);
        var opera = !!window.opera;
        var chrome = !edge && userAgentContains("chrome");
        var gecko = userAgentContains("gecko") && !webkit && !opera && !ie;
        var safari = !chrome && userAgentContains("safari");
        var phantom = userAgentContains("phantom");
        var opera12 = "OTransition" in style;
        var win = navigator.platform.indexOf("Win") === 0;
        var ie3d = ie && "transition" in style;
        var webkit3d = "WebKitCSSMatrix" in window && "m11" in new window.WebKitCSSMatrix() && !android23;
        var gecko3d = "MozPerspective" in style;
        var any3d = !window.L_DISABLE_3D && (ie3d || webkit3d || gecko3d) && !opera12 && !phantom;
        var mobile = typeof orientation !== "undefined" || userAgentContains("mobile");
        var mobileWebkit = mobile && webkit;
        var mobileWebkit3d = mobile && webkit3d;
        var msPointer = !window.PointerEvent && window.MSPointerEvent;
        var pointer = !!(window.PointerEvent || msPointer);
        var touchNative = "ontouchstart" in window || !!window.TouchEvent;
        var touch = !window.L_NO_TOUCH && (touchNative || pointer);
        var mobileOpera = mobile && opera;
        var mobileGecko = mobile && gecko;
        var retina = (window.devicePixelRatio || window.screen.deviceXDPI / window.screen.logicalXDPI) > 1;
        var passiveEvents = function() {
          var supportsPassiveOption = false;
          try {
            var opts = Object.defineProperty({}, "passive", {
              get: function() {
                supportsPassiveOption = true;
              }
            });
            window.addEventListener("testPassiveEventSupport", falseFn, opts);
            window.removeEventListener("testPassiveEventSupport", falseFn, opts);
          } catch (e) {
          }
          return supportsPassiveOption;
        }();
        var canvas$1 = function() {
          return !!document.createElement("canvas").getContext;
        }();
        var svg$1 = !!(document.createElementNS && svgCreate("svg").createSVGRect);
        var inlineSvg = !!svg$1 && function() {
          var div = document.createElement("div");
          div.innerHTML = "<svg/>";
          return (div.firstChild && div.firstChild.namespaceURI) === "http://www.w3.org/2000/svg";
        }();
        var vml = !svg$1 && function() {
          try {
            var div = document.createElement("div");
            div.innerHTML = '<v:shape adj="1"/>';
            var shape = div.firstChild;
            shape.style.behavior = "url(#default#VML)";
            return shape && typeof shape.adj === "object";
          } catch (e) {
            return false;
          }
        }();
        function userAgentContains(str) {
          return navigator.userAgent.toLowerCase().indexOf(str) >= 0;
        }
        var Browser = {
          ie,
          ielt9,
          edge,
          webkit,
          android,
          android23,
          androidStock,
          opera,
          chrome,
          gecko,
          safari,
          phantom,
          opera12,
          win,
          ie3d,
          webkit3d,
          gecko3d,
          any3d,
          mobile,
          mobileWebkit,
          mobileWebkit3d,
          msPointer,
          pointer,
          touch,
          touchNative,
          mobileOpera,
          mobileGecko,
          retina,
          passiveEvents,
          canvas: canvas$1,
          svg: svg$1,
          vml,
          inlineSvg
        };
        var POINTER_DOWN = Browser.msPointer ? "MSPointerDown" : "pointerdown";
        var POINTER_MOVE = Browser.msPointer ? "MSPointerMove" : "pointermove";
        var POINTER_UP = Browser.msPointer ? "MSPointerUp" : "pointerup";
        var POINTER_CANCEL = Browser.msPointer ? "MSPointerCancel" : "pointercancel";
        var pEvent = {
          touchstart: POINTER_DOWN,
          touchmove: POINTER_MOVE,
          touchend: POINTER_UP,
          touchcancel: POINTER_CANCEL
        };
        var handle = {
          touchstart: _onPointerStart,
          touchmove: _handlePointer,
          touchend: _handlePointer,
          touchcancel: _handlePointer
        };
        var _pointers = {};
        var _pointerDocListener = false;
        function addPointerListener(obj, type, handler) {
          if (type === "touchstart") {
            _addPointerDocListener();
          }
          if (!handle[type]) {
            console.warn("wrong event specified:", type);
            return L.Util.falseFn;
          }
          handler = handle[type].bind(this, handler);
          obj.addEventListener(pEvent[type], handler, false);
          return handler;
        }
        function removePointerListener(obj, type, handler) {
          if (!pEvent[type]) {
            console.warn("wrong event specified:", type);
            return;
          }
          obj.removeEventListener(pEvent[type], handler, false);
        }
        function _globalPointerDown(e) {
          _pointers[e.pointerId] = e;
        }
        function _globalPointerMove(e) {
          if (_pointers[e.pointerId]) {
            _pointers[e.pointerId] = e;
          }
        }
        function _globalPointerUp(e) {
          delete _pointers[e.pointerId];
        }
        function _addPointerDocListener() {
          if (!_pointerDocListener) {
            document.addEventListener(POINTER_DOWN, _globalPointerDown, true);
            document.addEventListener(POINTER_MOVE, _globalPointerMove, true);
            document.addEventListener(POINTER_UP, _globalPointerUp, true);
            document.addEventListener(POINTER_CANCEL, _globalPointerUp, true);
            _pointerDocListener = true;
          }
        }
        function _handlePointer(handler, e) {
          if (e.pointerType === (e.MSPOINTER_TYPE_MOUSE || "mouse")) {
            return;
          }
          e.touches = [];
          for (var i in _pointers) {
            e.touches.push(_pointers[i]);
          }
          e.changedTouches = [e];
          handler(e);
        }
        function _onPointerStart(handler, e) {
          if (e.MSPOINTER_TYPE_TOUCH && e.pointerType === e.MSPOINTER_TYPE_TOUCH) {
            preventDefault(e);
          }
          _handlePointer(handler, e);
        }
        function makeDblclick(event) {
          var newEvent = {}, prop, i;
          for (i in event) {
            prop = event[i];
            newEvent[i] = prop && prop.bind ? prop.bind(event) : prop;
          }
          event = newEvent;
          newEvent.type = "dblclick";
          newEvent.detail = 2;
          newEvent.isTrusted = false;
          newEvent._simulated = true;
          return newEvent;
        }
        var delay = 200;
        function addDoubleTapListener(obj, handler) {
          obj.addEventListener("dblclick", handler);
          var last = 0, detail;
          function simDblclick(e) {
            if (e.detail !== 1) {
              detail = e.detail;
              return;
            }
            if (e.pointerType === "mouse" || e.sourceCapabilities && !e.sourceCapabilities.firesTouchEvents) {
              return;
            }
            var now = Date.now();
            if (now - last <= delay) {
              detail++;
              if (detail === 2) {
                handler(makeDblclick(e));
              }
            } else {
              detail = 1;
            }
            last = now;
          }
          obj.addEventListener("click", simDblclick);
          return {
            dblclick: handler,
            simDblclick
          };
        }
        function removeDoubleTapListener(obj, handlers) {
          obj.removeEventListener("dblclick", handlers.dblclick);
          obj.removeEventListener("click", handlers.simDblclick);
        }
        var TRANSFORM = testProp(
          ["transform", "webkitTransform", "OTransform", "MozTransform", "msTransform"]
        );
        var TRANSITION = testProp(
          ["webkitTransition", "transition", "OTransition", "MozTransition", "msTransition"]
        );
        var TRANSITION_END = TRANSITION === "webkitTransition" || TRANSITION === "OTransition" ? TRANSITION + "End" : "transitionend";
        function get(id) {
          return typeof id === "string" ? document.getElementById(id) : id;
        }
        function getStyle(el, style2) {
          var value = el.style[style2] || el.currentStyle && el.currentStyle[style2];
          if ((!value || value === "auto") && document.defaultView) {
            var css = document.defaultView.getComputedStyle(el, null);
            value = css ? css[style2] : null;
          }
          return value === "auto" ? null : value;
        }
        function create$1(tagName, className, container) {
          var el = document.createElement(tagName);
          el.className = className || "";
          if (container) {
            container.appendChild(el);
          }
          return el;
        }
        function remove(el) {
          var parent = el.parentNode;
          if (parent) {
            parent.removeChild(el);
          }
        }
        function empty(el) {
          while (el.firstChild) {
            el.removeChild(el.firstChild);
          }
        }
        function toFront(el) {
          var parent = el.parentNode;
          if (parent && parent.lastChild !== el) {
            parent.appendChild(el);
          }
        }
        function toBack(el) {
          var parent = el.parentNode;
          if (parent && parent.firstChild !== el) {
            parent.insertBefore(el, parent.firstChild);
          }
        }
        function hasClass(el, name) {
          if (el.classList !== void 0) {
            return el.classList.contains(name);
          }
          var className = getClass(el);
          return className.length > 0 && new RegExp("(^|\\s)" + name + "(\\s|$)").test(className);
        }
        function addClass(el, name) {
          if (el.classList !== void 0) {
            var classes = splitWords(name);
            for (var i = 0, len = classes.length; i < len; i++) {
              el.classList.add(classes[i]);
            }
          } else if (!hasClass(el, name)) {
            var className = getClass(el);
            setClass(el, (className ? className + " " : "") + name);
          }
        }
        function removeClass(el, name) {
          if (el.classList !== void 0) {
            el.classList.remove(name);
          } else {
            setClass(el, trim((" " + getClass(el) + " ").replace(" " + name + " ", " ")));
          }
        }
        function setClass(el, name) {
          if (el.className.baseVal === void 0) {
            el.className = name;
          } else {
            el.className.baseVal = name;
          }
        }
        function getClass(el) {
          if (el.correspondingElement) {
            el = el.correspondingElement;
          }
          return el.className.baseVal === void 0 ? el.className : el.className.baseVal;
        }
        function setOpacity(el, value) {
          if ("opacity" in el.style) {
            el.style.opacity = value;
          } else if ("filter" in el.style) {
            _setOpacityIE(el, value);
          }
        }
        function _setOpacityIE(el, value) {
          var filter = false, filterName = "DXImageTransform.Microsoft.Alpha";
          try {
            filter = el.filters.item(filterName);
          } catch (e) {
            if (value === 1) {
              return;
            }
          }
          value = Math.round(value * 100);
          if (filter) {
            filter.Enabled = value !== 100;
            filter.Opacity = value;
          } else {
            el.style.filter += " progid:" + filterName + "(opacity=" + value + ")";
          }
        }
        function testProp(props) {
          var style2 = document.documentElement.style;
          for (var i = 0; i < props.length; i++) {
            if (props[i] in style2) {
              return props[i];
            }
          }
          return false;
        }
        function setTransform(el, offset, scale2) {
          var pos = offset || new Point(0, 0);
          el.style[TRANSFORM] = (Browser.ie3d ? "translate(" + pos.x + "px," + pos.y + "px)" : "translate3d(" + pos.x + "px," + pos.y + "px,0)") + (scale2 ? " scale(" + scale2 + ")" : "");
        }
        function setPosition(el, point) {
          el._leaflet_pos = point;
          if (Browser.any3d) {
            setTransform(el, point);
          } else {
            el.style.left = point.x + "px";
            el.style.top = point.y + "px";
          }
        }
        function getPosition(el) {
          return el._leaflet_pos || new Point(0, 0);
        }
        var disableTextSelection;
        var enableTextSelection;
        var _userSelect;
        if ("onselectstart" in document) {
          disableTextSelection = function() {
            on(window, "selectstart", preventDefault);
          };
          enableTextSelection = function() {
            off(window, "selectstart", preventDefault);
          };
        } else {
          var userSelectProperty = testProp(
            ["userSelect", "WebkitUserSelect", "OUserSelect", "MozUserSelect", "msUserSelect"]
          );
          disableTextSelection = function() {
            if (userSelectProperty) {
              var style2 = document.documentElement.style;
              _userSelect = style2[userSelectProperty];
              style2[userSelectProperty] = "none";
            }
          };
          enableTextSelection = function() {
            if (userSelectProperty) {
              document.documentElement.style[userSelectProperty] = _userSelect;
              _userSelect = void 0;
            }
          };
        }
        function disableImageDrag() {
          on(window, "dragstart", preventDefault);
        }
        function enableImageDrag() {
          off(window, "dragstart", preventDefault);
        }
        var _outlineElement, _outlineStyle;
        function preventOutline(element) {
          while (element.tabIndex === -1) {
            element = element.parentNode;
          }
          if (!element.style) {
            return;
          }
          restoreOutline();
          _outlineElement = element;
          _outlineStyle = element.style.outline;
          element.style.outline = "none";
          on(window, "keydown", restoreOutline);
        }
        function restoreOutline() {
          if (!_outlineElement) {
            return;
          }
          _outlineElement.style.outline = _outlineStyle;
          _outlineElement = void 0;
          _outlineStyle = void 0;
          off(window, "keydown", restoreOutline);
        }
        function getSizedParentNode(element) {
          do {
            element = element.parentNode;
          } while ((!element.offsetWidth || !element.offsetHeight) && element !== document.body);
          return element;
        }
        function getScale(element) {
          var rect = element.getBoundingClientRect();
          return {
            x: rect.width / element.offsetWidth || 1,
            y: rect.height / element.offsetHeight || 1,
            boundingClientRect: rect
          };
        }
        var DomUtil = {
          __proto__: null,
          TRANSFORM,
          TRANSITION,
          TRANSITION_END,
          get,
          getStyle,
          create: create$1,
          remove,
          empty,
          toFront,
          toBack,
          hasClass,
          addClass,
          removeClass,
          setClass,
          getClass,
          setOpacity,
          testProp,
          setTransform,
          setPosition,
          getPosition,
          get disableTextSelection() {
            return disableTextSelection;
          },
          get enableTextSelection() {
            return enableTextSelection;
          },
          disableImageDrag,
          enableImageDrag,
          preventOutline,
          restoreOutline,
          getSizedParentNode,
          getScale
        };
        function on(obj, types, fn, context) {
          if (types && typeof types === "object") {
            for (var type in types) {
              addOne(obj, type, types[type], fn);
            }
          } else {
            types = splitWords(types);
            for (var i = 0, len = types.length; i < len; i++) {
              addOne(obj, types[i], fn, context);
            }
          }
          return this;
        }
        var eventsKey = "_leaflet_events";
        function off(obj, types, fn, context) {
          if (arguments.length === 1) {
            batchRemove(obj);
            delete obj[eventsKey];
          } else if (types && typeof types === "object") {
            for (var type in types) {
              removeOne(obj, type, types[type], fn);
            }
          } else {
            types = splitWords(types);
            if (arguments.length === 2) {
              batchRemove(obj, function(type2) {
                return indexOf(types, type2) !== -1;
              });
            } else {
              for (var i = 0, len = types.length; i < len; i++) {
                removeOne(obj, types[i], fn, context);
              }
            }
          }
          return this;
        }
        function batchRemove(obj, filterFn) {
          for (var id in obj[eventsKey]) {
            var type = id.split(/\d/)[0];
            if (!filterFn || filterFn(type)) {
              removeOne(obj, type, null, null, id);
            }
          }
        }
        var mouseSubst = {
          mouseenter: "mouseover",
          mouseleave: "mouseout",
          wheel: !("onwheel" in window) && "mousewheel"
        };
        function addOne(obj, type, fn, context) {
          var id = type + stamp(fn) + (context ? "_" + stamp(context) : "");
          if (obj[eventsKey] && obj[eventsKey][id]) {
            return this;
          }
          var handler = function(e) {
            return fn.call(context || obj, e || window.event);
          };
          var originalHandler = handler;
          if (!Browser.touchNative && Browser.pointer && type.indexOf("touch") === 0) {
            handler = addPointerListener(obj, type, handler);
          } else if (Browser.touch && type === "dblclick") {
            handler = addDoubleTapListener(obj, handler);
          } else if ("addEventListener" in obj) {
            if (type === "touchstart" || type === "touchmove" || type === "wheel" || type === "mousewheel") {
              obj.addEventListener(mouseSubst[type] || type, handler, Browser.passiveEvents ? { passive: false } : false);
            } else if (type === "mouseenter" || type === "mouseleave") {
              handler = function(e) {
                e = e || window.event;
                if (isExternalTarget(obj, e)) {
                  originalHandler(e);
                }
              };
              obj.addEventListener(mouseSubst[type], handler, false);
            } else {
              obj.addEventListener(type, originalHandler, false);
            }
          } else {
            obj.attachEvent("on" + type, handler);
          }
          obj[eventsKey] = obj[eventsKey] || {};
          obj[eventsKey][id] = handler;
        }
        function removeOne(obj, type, fn, context, id) {
          id = id || type + stamp(fn) + (context ? "_" + stamp(context) : "");
          var handler = obj[eventsKey] && obj[eventsKey][id];
          if (!handler) {
            return this;
          }
          if (!Browser.touchNative && Browser.pointer && type.indexOf("touch") === 0) {
            removePointerListener(obj, type, handler);
          } else if (Browser.touch && type === "dblclick") {
            removeDoubleTapListener(obj, handler);
          } else if ("removeEventListener" in obj) {
            obj.removeEventListener(mouseSubst[type] || type, handler, false);
          } else {
            obj.detachEvent("on" + type, handler);
          }
          obj[eventsKey][id] = null;
        }
        function stopPropagation(e) {
          if (e.stopPropagation) {
            e.stopPropagation();
          } else if (e.originalEvent) {
            e.originalEvent._stopped = true;
          } else {
            e.cancelBubble = true;
          }
          return this;
        }
        function disableScrollPropagation(el) {
          addOne(el, "wheel", stopPropagation);
          return this;
        }
        function disableClickPropagation(el) {
          on(el, "mousedown touchstart dblclick contextmenu", stopPropagation);
          el["_leaflet_disable_click"] = true;
          return this;
        }
        function preventDefault(e) {
          if (e.preventDefault) {
            e.preventDefault();
          } else {
            e.returnValue = false;
          }
          return this;
        }
        function stop(e) {
          preventDefault(e);
          stopPropagation(e);
          return this;
        }
        function getMousePosition(e, container) {
          if (!container) {
            return new Point(e.clientX, e.clientY);
          }
          var scale2 = getScale(container), offset = scale2.boundingClientRect;
          return new Point(
            (e.clientX - offset.left) / scale2.x - container.clientLeft,
            (e.clientY - offset.top) / scale2.y - container.clientTop
          );
        }
        var wheelPxFactor = Browser.win && Browser.chrome ? 2 * window.devicePixelRatio : Browser.gecko ? window.devicePixelRatio : 1;
        function getWheelDelta(e) {
          return Browser.edge ? e.wheelDeltaY / 2 : e.deltaY && e.deltaMode === 0 ? -e.deltaY / wheelPxFactor : e.deltaY && e.deltaMode === 1 ? -e.deltaY * 20 : e.deltaY && e.deltaMode === 2 ? -e.deltaY * 60 : e.deltaX || e.deltaZ ? 0 : e.wheelDelta ? (e.wheelDeltaY || e.wheelDelta) / 2 : e.detail && Math.abs(e.detail) < 32765 ? -e.detail * 20 : e.detail ? e.detail / -32765 * 60 : 0;
        }
        function isExternalTarget(el, e) {
          var related = e.relatedTarget;
          if (!related) {
            return true;
          }
          try {
            while (related && related !== el) {
              related = related.parentNode;
            }
          } catch (err) {
            return false;
          }
          return related !== el;
        }
        var DomEvent = {
          __proto__: null,
          on,
          off,
          stopPropagation,
          disableScrollPropagation,
          disableClickPropagation,
          preventDefault,
          stop,
          getMousePosition,
          getWheelDelta,
          isExternalTarget,
          addListener: on,
          removeListener: off
        };
        var PosAnimation = Evented.extend({
          run: function(el, newPos, duration, easeLinearity) {
            this.stop();
            this._el = el;
            this._inProgress = true;
            this._duration = duration || 0.25;
            this._easeOutPower = 1 / Math.max(easeLinearity || 0.5, 0.2);
            this._startPos = getPosition(el);
            this._offset = newPos.subtract(this._startPos);
            this._startTime = +new Date();
            this.fire("start");
            this._animate();
          },
          stop: function() {
            if (!this._inProgress) {
              return;
            }
            this._step(true);
            this._complete();
          },
          _animate: function() {
            this._animId = requestAnimFrame(this._animate, this);
            this._step();
          },
          _step: function(round) {
            var elapsed = +new Date() - this._startTime, duration = this._duration * 1e3;
            if (elapsed < duration) {
              this._runFrame(this._easeOut(elapsed / duration), round);
            } else {
              this._runFrame(1);
              this._complete();
            }
          },
          _runFrame: function(progress, round) {
            var pos = this._startPos.add(this._offset.multiplyBy(progress));
            if (round) {
              pos._round();
            }
            setPosition(this._el, pos);
            this.fire("step");
          },
          _complete: function() {
            cancelAnimFrame(this._animId);
            this._inProgress = false;
            this.fire("end");
          },
          _easeOut: function(t) {
            return 1 - Math.pow(1 - t, this._easeOutPower);
          }
        });
        var Map = Evented.extend({
          options: {
            crs: EPSG3857,
            center: void 0,
            zoom: void 0,
            minZoom: void 0,
            maxZoom: void 0,
            layers: [],
            maxBounds: void 0,
            renderer: void 0,
            zoomAnimation: true,
            zoomAnimationThreshold: 4,
            fadeAnimation: true,
            markerZoomAnimation: true,
            transform3DLimit: 8388608,
            zoomSnap: 1,
            zoomDelta: 1,
            trackResize: true
          },
          initialize: function(id, options) {
            options = setOptions(this, options);
            this._handlers = [];
            this._layers = {};
            this._zoomBoundLayers = {};
            this._sizeChanged = true;
            this._initContainer(id);
            this._initLayout();
            this._onResize = bind(this._onResize, this);
            this._initEvents();
            if (options.maxBounds) {
              this.setMaxBounds(options.maxBounds);
            }
            if (options.zoom !== void 0) {
              this._zoom = this._limitZoom(options.zoom);
            }
            if (options.center && options.zoom !== void 0) {
              this.setView(toLatLng(options.center), options.zoom, { reset: true });
            }
            this.callInitHooks();
            this._zoomAnimated = TRANSITION && Browser.any3d && !Browser.mobileOpera && this.options.zoomAnimation;
            if (this._zoomAnimated) {
              this._createAnimProxy();
              on(this._proxy, TRANSITION_END, this._catchTransitionEnd, this);
            }
            this._addLayers(this.options.layers);
          },
          setView: function(center, zoom2, options) {
            zoom2 = zoom2 === void 0 ? this._zoom : this._limitZoom(zoom2);
            center = this._limitCenter(toLatLng(center), zoom2, this.options.maxBounds);
            options = options || {};
            this._stop();
            if (this._loaded && !options.reset && options !== true) {
              if (options.animate !== void 0) {
                options.zoom = extend({ animate: options.animate }, options.zoom);
                options.pan = extend({ animate: options.animate, duration: options.duration }, options.pan);
              }
              var moved = this._zoom !== zoom2 ? this._tryAnimatedZoom && this._tryAnimatedZoom(center, zoom2, options.zoom) : this._tryAnimatedPan(center, options.pan);
              if (moved) {
                clearTimeout(this._sizeTimer);
                return this;
              }
            }
            this._resetView(center, zoom2);
            return this;
          },
          setZoom: function(zoom2, options) {
            if (!this._loaded) {
              this._zoom = zoom2;
              return this;
            }
            return this.setView(this.getCenter(), zoom2, { zoom: options });
          },
          zoomIn: function(delta, options) {
            delta = delta || (Browser.any3d ? this.options.zoomDelta : 1);
            return this.setZoom(this._zoom + delta, options);
          },
          zoomOut: function(delta, options) {
            delta = delta || (Browser.any3d ? this.options.zoomDelta : 1);
            return this.setZoom(this._zoom - delta, options);
          },
          setZoomAround: function(latlng, zoom2, options) {
            var scale2 = this.getZoomScale(zoom2), viewHalf = this.getSize().divideBy(2), containerPoint = latlng instanceof Point ? latlng : this.latLngToContainerPoint(latlng), centerOffset = containerPoint.subtract(viewHalf).multiplyBy(1 - 1 / scale2), newCenter = this.containerPointToLatLng(viewHalf.add(centerOffset));
            return this.setView(newCenter, zoom2, { zoom: options });
          },
          _getBoundsCenterZoom: function(bounds, options) {
            options = options || {};
            bounds = bounds.getBounds ? bounds.getBounds() : toLatLngBounds(bounds);
            var paddingTL = toPoint(options.paddingTopLeft || options.padding || [0, 0]), paddingBR = toPoint(options.paddingBottomRight || options.padding || [0, 0]), zoom2 = this.getBoundsZoom(bounds, false, paddingTL.add(paddingBR));
            zoom2 = typeof options.maxZoom === "number" ? Math.min(options.maxZoom, zoom2) : zoom2;
            if (zoom2 === Infinity) {
              return {
                center: bounds.getCenter(),
                zoom: zoom2
              };
            }
            var paddingOffset = paddingBR.subtract(paddingTL).divideBy(2), swPoint = this.project(bounds.getSouthWest(), zoom2), nePoint = this.project(bounds.getNorthEast(), zoom2), center = this.unproject(swPoint.add(nePoint).divideBy(2).add(paddingOffset), zoom2);
            return {
              center,
              zoom: zoom2
            };
          },
          fitBounds: function(bounds, options) {
            bounds = toLatLngBounds(bounds);
            if (!bounds.isValid()) {
              throw new Error("Bounds are not valid.");
            }
            var target = this._getBoundsCenterZoom(bounds, options);
            return this.setView(target.center, target.zoom, options);
          },
          fitWorld: function(options) {
            return this.fitBounds([[-90, -180], [90, 180]], options);
          },
          panTo: function(center, options) {
            return this.setView(center, this._zoom, { pan: options });
          },
          panBy: function(offset, options) {
            offset = toPoint(offset).round();
            options = options || {};
            if (!offset.x && !offset.y) {
              return this.fire("moveend");
            }
            if (options.animate !== true && !this.getSize().contains(offset)) {
              this._resetView(this.unproject(this.project(this.getCenter()).add(offset)), this.getZoom());
              return this;
            }
            if (!this._panAnim) {
              this._panAnim = new PosAnimation();
              this._panAnim.on({
                "step": this._onPanTransitionStep,
                "end": this._onPanTransitionEnd
              }, this);
            }
            if (!options.noMoveStart) {
              this.fire("movestart");
            }
            if (options.animate !== false) {
              addClass(this._mapPane, "leaflet-pan-anim");
              var newPos = this._getMapPanePos().subtract(offset).round();
              this._panAnim.run(this._mapPane, newPos, options.duration || 0.25, options.easeLinearity);
            } else {
              this._rawPanBy(offset);
              this.fire("move").fire("moveend");
            }
            return this;
          },
          flyTo: function(targetCenter, targetZoom, options) {
            options = options || {};
            if (options.animate === false || !Browser.any3d) {
              return this.setView(targetCenter, targetZoom, options);
            }
            this._stop();
            var from = this.project(this.getCenter()), to = this.project(targetCenter), size = this.getSize(), startZoom = this._zoom;
            targetCenter = toLatLng(targetCenter);
            targetZoom = targetZoom === void 0 ? startZoom : targetZoom;
            var w0 = Math.max(size.x, size.y), w1 = w0 * this.getZoomScale(startZoom, targetZoom), u1 = to.distanceTo(from) || 1, rho = 1.42, rho2 = rho * rho;
            function r(i) {
              var s1 = i ? -1 : 1, s2 = i ? w1 : w0, t1 = w1 * w1 - w0 * w0 + s1 * rho2 * rho2 * u1 * u1, b1 = 2 * s2 * rho2 * u1, b = t1 / b1, sq = Math.sqrt(b * b + 1) - b;
              var log = sq < 1e-9 ? -18 : Math.log(sq);
              return log;
            }
            function sinh(n) {
              return (Math.exp(n) - Math.exp(-n)) / 2;
            }
            function cosh(n) {
              return (Math.exp(n) + Math.exp(-n)) / 2;
            }
            function tanh(n) {
              return sinh(n) / cosh(n);
            }
            var r0 = r(0);
            function w(s) {
              return w0 * (cosh(r0) / cosh(r0 + rho * s));
            }
            function u(s) {
              return w0 * (cosh(r0) * tanh(r0 + rho * s) - sinh(r0)) / rho2;
            }
            function easeOut(t) {
              return 1 - Math.pow(1 - t, 1.5);
            }
            var start = Date.now(), S = (r(1) - r0) / rho, duration = options.duration ? 1e3 * options.duration : 1e3 * S * 0.8;
            function frame() {
              var t = (Date.now() - start) / duration, s = easeOut(t) * S;
              if (t <= 1) {
                this._flyToFrame = requestAnimFrame(frame, this);
                this._move(
                  this.unproject(from.add(to.subtract(from).multiplyBy(u(s) / u1)), startZoom),
                  this.getScaleZoom(w0 / w(s), startZoom),
                  { flyTo: true }
                );
              } else {
                this._move(targetCenter, targetZoom)._moveEnd(true);
              }
            }
            this._moveStart(true, options.noMoveStart);
            frame.call(this);
            return this;
          },
          flyToBounds: function(bounds, options) {
            var target = this._getBoundsCenterZoom(bounds, options);
            return this.flyTo(target.center, target.zoom, options);
          },
          setMaxBounds: function(bounds) {
            bounds = toLatLngBounds(bounds);
            if (!bounds.isValid()) {
              this.options.maxBounds = null;
              return this.off("moveend", this._panInsideMaxBounds);
            } else if (this.options.maxBounds) {
              this.off("moveend", this._panInsideMaxBounds);
            }
            this.options.maxBounds = bounds;
            if (this._loaded) {
              this._panInsideMaxBounds();
            }
            return this.on("moveend", this._panInsideMaxBounds);
          },
          setMinZoom: function(zoom2) {
            var oldZoom = this.options.minZoom;
            this.options.minZoom = zoom2;
            if (this._loaded && oldZoom !== zoom2) {
              this.fire("zoomlevelschange");
              if (this.getZoom() < this.options.minZoom) {
                return this.setZoom(zoom2);
              }
            }
            return this;
          },
          setMaxZoom: function(zoom2) {
            var oldZoom = this.options.maxZoom;
            this.options.maxZoom = zoom2;
            if (this._loaded && oldZoom !== zoom2) {
              this.fire("zoomlevelschange");
              if (this.getZoom() > this.options.maxZoom) {
                return this.setZoom(zoom2);
              }
            }
            return this;
          },
          panInsideBounds: function(bounds, options) {
            this._enforcingBounds = true;
            var center = this.getCenter(), newCenter = this._limitCenter(center, this._zoom, toLatLngBounds(bounds));
            if (!center.equals(newCenter)) {
              this.panTo(newCenter, options);
            }
            this._enforcingBounds = false;
            return this;
          },
          panInside: function(latlng, options) {
            options = options || {};
            var paddingTL = toPoint(options.paddingTopLeft || options.padding || [0, 0]), paddingBR = toPoint(options.paddingBottomRight || options.padding || [0, 0]), pixelCenter = this.project(this.getCenter()), pixelPoint = this.project(latlng), pixelBounds = this.getPixelBounds(), paddedBounds = toBounds([pixelBounds.min.add(paddingTL), pixelBounds.max.subtract(paddingBR)]), paddedSize = paddedBounds.getSize();
            if (!paddedBounds.contains(pixelPoint)) {
              this._enforcingBounds = true;
              var centerOffset = pixelPoint.subtract(paddedBounds.getCenter());
              var offset = paddedBounds.extend(pixelPoint).getSize().subtract(paddedSize);
              pixelCenter.x += centerOffset.x < 0 ? -offset.x : offset.x;
              pixelCenter.y += centerOffset.y < 0 ? -offset.y : offset.y;
              this.panTo(this.unproject(pixelCenter), options);
              this._enforcingBounds = false;
            }
            return this;
          },
          invalidateSize: function(options) {
            if (!this._loaded) {
              return this;
            }
            options = extend({
              animate: false,
              pan: true
            }, options === true ? { animate: true } : options);
            var oldSize = this.getSize();
            this._sizeChanged = true;
            this._lastCenter = null;
            var newSize = this.getSize(), oldCenter = oldSize.divideBy(2).round(), newCenter = newSize.divideBy(2).round(), offset = oldCenter.subtract(newCenter);
            if (!offset.x && !offset.y) {
              return this;
            }
            if (options.animate && options.pan) {
              this.panBy(offset);
            } else {
              if (options.pan) {
                this._rawPanBy(offset);
              }
              this.fire("move");
              if (options.debounceMoveend) {
                clearTimeout(this._sizeTimer);
                this._sizeTimer = setTimeout(bind(this.fire, this, "moveend"), 200);
              } else {
                this.fire("moveend");
              }
            }
            return this.fire("resize", {
              oldSize,
              newSize
            });
          },
          stop: function() {
            this.setZoom(this._limitZoom(this._zoom));
            if (!this.options.zoomSnap) {
              this.fire("viewreset");
            }
            return this._stop();
          },
          locate: function(options) {
            options = this._locateOptions = extend({
              timeout: 1e4,
              watch: false
            }, options);
            if (!("geolocation" in navigator)) {
              this._handleGeolocationError({
                code: 0,
                message: "Geolocation not supported."
              });
              return this;
            }
            var onResponse = bind(this._handleGeolocationResponse, this), onError = bind(this._handleGeolocationError, this);
            if (options.watch) {
              this._locationWatchId = navigator.geolocation.watchPosition(onResponse, onError, options);
            } else {
              navigator.geolocation.getCurrentPosition(onResponse, onError, options);
            }
            return this;
          },
          stopLocate: function() {
            if (navigator.geolocation && navigator.geolocation.clearWatch) {
              navigator.geolocation.clearWatch(this._locationWatchId);
            }
            if (this._locateOptions) {
              this._locateOptions.setView = false;
            }
            return this;
          },
          _handleGeolocationError: function(error) {
            if (!this._container._leaflet_id) {
              return;
            }
            var c = error.code, message = error.message || (c === 1 ? "permission denied" : c === 2 ? "position unavailable" : "timeout");
            if (this._locateOptions.setView && !this._loaded) {
              this.fitWorld();
            }
            this.fire("locationerror", {
              code: c,
              message: "Geolocation error: " + message + "."
            });
          },
          _handleGeolocationResponse: function(pos) {
            if (!this._container._leaflet_id) {
              return;
            }
            var lat = pos.coords.latitude, lng = pos.coords.longitude, latlng = new LatLng(lat, lng), bounds = latlng.toBounds(pos.coords.accuracy * 2), options = this._locateOptions;
            if (options.setView) {
              var zoom2 = this.getBoundsZoom(bounds);
              this.setView(latlng, options.maxZoom ? Math.min(zoom2, options.maxZoom) : zoom2);
            }
            var data = {
              latlng,
              bounds,
              timestamp: pos.timestamp
            };
            for (var i in pos.coords) {
              if (typeof pos.coords[i] === "number") {
                data[i] = pos.coords[i];
              }
            }
            this.fire("locationfound", data);
          },
          addHandler: function(name, HandlerClass) {
            if (!HandlerClass) {
              return this;
            }
            var handler = this[name] = new HandlerClass(this);
            this._handlers.push(handler);
            if (this.options[name]) {
              handler.enable();
            }
            return this;
          },
          remove: function() {
            this._initEvents(true);
            if (this.options.maxBounds) {
              this.off("moveend", this._panInsideMaxBounds);
            }
            if (this._containerId !== this._container._leaflet_id) {
              throw new Error("Map container is being reused by another instance");
            }
            try {
              delete this._container._leaflet_id;
              delete this._containerId;
            } catch (e) {
              this._container._leaflet_id = void 0;
              this._containerId = void 0;
            }
            if (this._locationWatchId !== void 0) {
              this.stopLocate();
            }
            this._stop();
            remove(this._mapPane);
            if (this._clearControlPos) {
              this._clearControlPos();
            }
            if (this._resizeRequest) {
              cancelAnimFrame(this._resizeRequest);
              this._resizeRequest = null;
            }
            this._clearHandlers();
            if (this._loaded) {
              this.fire("unload");
            }
            var i;
            for (i in this._layers) {
              this._layers[i].remove();
            }
            for (i in this._panes) {
              remove(this._panes[i]);
            }
            this._layers = [];
            this._panes = [];
            delete this._mapPane;
            delete this._renderer;
            return this;
          },
          createPane: function(name, container) {
            var className = "leaflet-pane" + (name ? " leaflet-" + name.replace("Pane", "") + "-pane" : ""), pane = create$1("div", className, container || this._mapPane);
            if (name) {
              this._panes[name] = pane;
            }
            return pane;
          },
          getCenter: function() {
            this._checkIfLoaded();
            if (this._lastCenter && !this._moved()) {
              return this._lastCenter;
            }
            return this.layerPointToLatLng(this._getCenterLayerPoint());
          },
          getZoom: function() {
            return this._zoom;
          },
          getBounds: function() {
            var bounds = this.getPixelBounds(), sw = this.unproject(bounds.getBottomLeft()), ne = this.unproject(bounds.getTopRight());
            return new LatLngBounds(sw, ne);
          },
          getMinZoom: function() {
            return this.options.minZoom === void 0 ? this._layersMinZoom || 0 : this.options.minZoom;
          },
          getMaxZoom: function() {
            return this.options.maxZoom === void 0 ? this._layersMaxZoom === void 0 ? Infinity : this._layersMaxZoom : this.options.maxZoom;
          },
          getBoundsZoom: function(bounds, inside, padding) {
            bounds = toLatLngBounds(bounds);
            padding = toPoint(padding || [0, 0]);
            var zoom2 = this.getZoom() || 0, min = this.getMinZoom(), max = this.getMaxZoom(), nw = bounds.getNorthWest(), se = bounds.getSouthEast(), size = this.getSize().subtract(padding), boundsSize = toBounds(this.project(se, zoom2), this.project(nw, zoom2)).getSize(), snap = Browser.any3d ? this.options.zoomSnap : 1, scalex = size.x / boundsSize.x, scaley = size.y / boundsSize.y, scale2 = inside ? Math.max(scalex, scaley) : Math.min(scalex, scaley);
            zoom2 = this.getScaleZoom(scale2, zoom2);
            if (snap) {
              zoom2 = Math.round(zoom2 / (snap / 100)) * (snap / 100);
              zoom2 = inside ? Math.ceil(zoom2 / snap) * snap : Math.floor(zoom2 / snap) * snap;
            }
            return Math.max(min, Math.min(max, zoom2));
          },
          getSize: function() {
            if (!this._size || this._sizeChanged) {
              this._size = new Point(
                this._container.clientWidth || 0,
                this._container.clientHeight || 0
              );
              this._sizeChanged = false;
            }
            return this._size.clone();
          },
          getPixelBounds: function(center, zoom2) {
            var topLeftPoint = this._getTopLeftPoint(center, zoom2);
            return new Bounds(topLeftPoint, topLeftPoint.add(this.getSize()));
          },
          getPixelOrigin: function() {
            this._checkIfLoaded();
            return this._pixelOrigin;
          },
          getPixelWorldBounds: function(zoom2) {
            return this.options.crs.getProjectedBounds(zoom2 === void 0 ? this.getZoom() : zoom2);
          },
          getPane: function(pane) {
            return typeof pane === "string" ? this._panes[pane] : pane;
          },
          getPanes: function() {
            return this._panes;
          },
          getContainer: function() {
            return this._container;
          },
          getZoomScale: function(toZoom, fromZoom) {
            var crs = this.options.crs;
            fromZoom = fromZoom === void 0 ? this._zoom : fromZoom;
            return crs.scale(toZoom) / crs.scale(fromZoom);
          },
          getScaleZoom: function(scale2, fromZoom) {
            var crs = this.options.crs;
            fromZoom = fromZoom === void 0 ? this._zoom : fromZoom;
            var zoom2 = crs.zoom(scale2 * crs.scale(fromZoom));
            return isNaN(zoom2) ? Infinity : zoom2;
          },
          project: function(latlng, zoom2) {
            zoom2 = zoom2 === void 0 ? this._zoom : zoom2;
            return this.options.crs.latLngToPoint(toLatLng(latlng), zoom2);
          },
          unproject: function(point, zoom2) {
            zoom2 = zoom2 === void 0 ? this._zoom : zoom2;
            return this.options.crs.pointToLatLng(toPoint(point), zoom2);
          },
          layerPointToLatLng: function(point) {
            var projectedPoint = toPoint(point).add(this.getPixelOrigin());
            return this.unproject(projectedPoint);
          },
          latLngToLayerPoint: function(latlng) {
            var projectedPoint = this.project(toLatLng(latlng))._round();
            return projectedPoint._subtract(this.getPixelOrigin());
          },
          wrapLatLng: function(latlng) {
            return this.options.crs.wrapLatLng(toLatLng(latlng));
          },
          wrapLatLngBounds: function(latlng) {
            return this.options.crs.wrapLatLngBounds(toLatLngBounds(latlng));
          },
          distance: function(latlng1, latlng2) {
            return this.options.crs.distance(toLatLng(latlng1), toLatLng(latlng2));
          },
          containerPointToLayerPoint: function(point) {
            return toPoint(point).subtract(this._getMapPanePos());
          },
          layerPointToContainerPoint: function(point) {
            return toPoint(point).add(this._getMapPanePos());
          },
          containerPointToLatLng: function(point) {
            var layerPoint = this.containerPointToLayerPoint(toPoint(point));
            return this.layerPointToLatLng(layerPoint);
          },
          latLngToContainerPoint: function(latlng) {
            return this.layerPointToContainerPoint(this.latLngToLayerPoint(toLatLng(latlng)));
          },
          mouseEventToContainerPoint: function(e) {
            return getMousePosition(e, this._container);
          },
          mouseEventToLayerPoint: function(e) {
            return this.containerPointToLayerPoint(this.mouseEventToContainerPoint(e));
          },
          mouseEventToLatLng: function(e) {
            return this.layerPointToLatLng(this.mouseEventToLayerPoint(e));
          },
          _initContainer: function(id) {
            var container = this._container = get(id);
            if (!container) {
              throw new Error("Map container not found.");
            } else if (container._leaflet_id) {
              throw new Error("Map container is already initialized.");
            }
            on(container, "scroll", this._onScroll, this);
            this._containerId = stamp(container);
          },
          _initLayout: function() {
            var container = this._container;
            this._fadeAnimated = this.options.fadeAnimation && Browser.any3d;
            addClass(container, "leaflet-container" + (Browser.touch ? " leaflet-touch" : "") + (Browser.retina ? " leaflet-retina" : "") + (Browser.ielt9 ? " leaflet-oldie" : "") + (Browser.safari ? " leaflet-safari" : "") + (this._fadeAnimated ? " leaflet-fade-anim" : ""));
            var position = getStyle(container, "position");
            if (position !== "absolute" && position !== "relative" && position !== "fixed") {
              container.style.position = "relative";
            }
            this._initPanes();
            if (this._initControlPos) {
              this._initControlPos();
            }
          },
          _initPanes: function() {
            var panes = this._panes = {};
            this._paneRenderers = {};
            this._mapPane = this.createPane("mapPane", this._container);
            setPosition(this._mapPane, new Point(0, 0));
            this.createPane("tilePane");
            this.createPane("overlayPane");
            this.createPane("shadowPane");
            this.createPane("markerPane");
            this.createPane("tooltipPane");
            this.createPane("popupPane");
            if (!this.options.markerZoomAnimation) {
              addClass(panes.markerPane, "leaflet-zoom-hide");
              addClass(panes.shadowPane, "leaflet-zoom-hide");
            }
          },
          _resetView: function(center, zoom2) {
            setPosition(this._mapPane, new Point(0, 0));
            var loading = !this._loaded;
            this._loaded = true;
            zoom2 = this._limitZoom(zoom2);
            this.fire("viewprereset");
            var zoomChanged = this._zoom !== zoom2;
            this._moveStart(zoomChanged, false)._move(center, zoom2)._moveEnd(zoomChanged);
            this.fire("viewreset");
            if (loading) {
              this.fire("load");
            }
          },
          _moveStart: function(zoomChanged, noMoveStart) {
            if (zoomChanged) {
              this.fire("zoomstart");
            }
            if (!noMoveStart) {
              this.fire("movestart");
            }
            return this;
          },
          _move: function(center, zoom2, data, supressEvent) {
            if (zoom2 === void 0) {
              zoom2 = this._zoom;
            }
            var zoomChanged = this._zoom !== zoom2;
            this._zoom = zoom2;
            this._lastCenter = center;
            this._pixelOrigin = this._getNewPixelOrigin(center);
            if (!supressEvent) {
              if (zoomChanged || data && data.pinch) {
                this.fire("zoom", data);
              }
              this.fire("move", data);
            } else if (data && data.pinch) {
              this.fire("zoom", data);
            }
            return this;
          },
          _moveEnd: function(zoomChanged) {
            if (zoomChanged) {
              this.fire("zoomend");
            }
            return this.fire("moveend");
          },
          _stop: function() {
            cancelAnimFrame(this._flyToFrame);
            if (this._panAnim) {
              this._panAnim.stop();
            }
            return this;
          },
          _rawPanBy: function(offset) {
            setPosition(this._mapPane, this._getMapPanePos().subtract(offset));
          },
          _getZoomSpan: function() {
            return this.getMaxZoom() - this.getMinZoom();
          },
          _panInsideMaxBounds: function() {
            if (!this._enforcingBounds) {
              this.panInsideBounds(this.options.maxBounds);
            }
          },
          _checkIfLoaded: function() {
            if (!this._loaded) {
              throw new Error("Set map center and zoom first.");
            }
          },
          _initEvents: function(remove2) {
            this._targets = {};
            this._targets[stamp(this._container)] = this;
            var onOff = remove2 ? off : on;
            onOff(this._container, "click dblclick mousedown mouseup mouseover mouseout mousemove contextmenu keypress keydown keyup", this._handleDOMEvent, this);
            if (this.options.trackResize) {
              onOff(window, "resize", this._onResize, this);
            }
            if (Browser.any3d && this.options.transform3DLimit) {
              (remove2 ? this.off : this.on).call(this, "moveend", this._onMoveEnd);
            }
          },
          _onResize: function() {
            cancelAnimFrame(this._resizeRequest);
            this._resizeRequest = requestAnimFrame(
              function() {
                this.invalidateSize({ debounceMoveend: true });
              },
              this
            );
          },
          _onScroll: function() {
            this._container.scrollTop = 0;
            this._container.scrollLeft = 0;
          },
          _onMoveEnd: function() {
            var pos = this._getMapPanePos();
            if (Math.max(Math.abs(pos.x), Math.abs(pos.y)) >= this.options.transform3DLimit) {
              this._resetView(this.getCenter(), this.getZoom());
            }
          },
          _findEventTargets: function(e, type) {
            var targets = [], target, isHover = type === "mouseout" || type === "mouseover", src = e.target || e.srcElement, dragging = false;
            while (src) {
              target = this._targets[stamp(src)];
              if (target && (type === "click" || type === "preclick") && this._draggableMoved(target)) {
                dragging = true;
                break;
              }
              if (target && target.listens(type, true)) {
                if (isHover && !isExternalTarget(src, e)) {
                  break;
                }
                targets.push(target);
                if (isHover) {
                  break;
                }
              }
              if (src === this._container) {
                break;
              }
              src = src.parentNode;
            }
            if (!targets.length && !dragging && !isHover && this.listens(type, true)) {
              targets = [this];
            }
            return targets;
          },
          _isClickDisabled: function(el) {
            while (el !== this._container) {
              if (el["_leaflet_disable_click"]) {
                return true;
              }
              el = el.parentNode;
            }
          },
          _handleDOMEvent: function(e) {
            var el = e.target || e.srcElement;
            if (!this._loaded || el["_leaflet_disable_events"] || e.type === "click" && this._isClickDisabled(el)) {
              return;
            }
            var type = e.type;
            if (type === "mousedown") {
              preventOutline(el);
            }
            this._fireDOMEvent(e, type);
          },
          _mouseEvents: ["click", "dblclick", "mouseover", "mouseout", "contextmenu"],
          _fireDOMEvent: function(e, type, canvasTargets) {
            if (e.type === "click") {
              var synth = extend({}, e);
              synth.type = "preclick";
              this._fireDOMEvent(synth, synth.type, canvasTargets);
            }
            var targets = this._findEventTargets(e, type);
            if (canvasTargets) {
              var filtered = [];
              for (var i = 0; i < canvasTargets.length; i++) {
                if (canvasTargets[i].listens(type, true)) {
                  filtered.push(canvasTargets[i]);
                }
              }
              targets = filtered.concat(targets);
            }
            if (!targets.length) {
              return;
            }
            if (type === "contextmenu") {
              preventDefault(e);
            }
            var target = targets[0];
            var data = {
              originalEvent: e
            };
            if (e.type !== "keypress" && e.type !== "keydown" && e.type !== "keyup") {
              var isMarker = target.getLatLng && (!target._radius || target._radius <= 10);
              data.containerPoint = isMarker ? this.latLngToContainerPoint(target.getLatLng()) : this.mouseEventToContainerPoint(e);
              data.layerPoint = this.containerPointToLayerPoint(data.containerPoint);
              data.latlng = isMarker ? target.getLatLng() : this.layerPointToLatLng(data.layerPoint);
            }
            for (i = 0; i < targets.length; i++) {
              targets[i].fire(type, data, true);
              if (data.originalEvent._stopped || targets[i].options.bubblingMouseEvents === false && indexOf(this._mouseEvents, type) !== -1) {
                return;
              }
            }
          },
          _draggableMoved: function(obj) {
            obj = obj.dragging && obj.dragging.enabled() ? obj : this;
            return obj.dragging && obj.dragging.moved() || this.boxZoom && this.boxZoom.moved();
          },
          _clearHandlers: function() {
            for (var i = 0, len = this._handlers.length; i < len; i++) {
              this._handlers[i].disable();
            }
          },
          whenReady: function(callback, context) {
            if (this._loaded) {
              callback.call(context || this, { target: this });
            } else {
              this.on("load", callback, context);
            }
            return this;
          },
          _getMapPanePos: function() {
            return getPosition(this._mapPane) || new Point(0, 0);
          },
          _moved: function() {
            var pos = this._getMapPanePos();
            return pos && !pos.equals([0, 0]);
          },
          _getTopLeftPoint: function(center, zoom2) {
            var pixelOrigin = center && zoom2 !== void 0 ? this._getNewPixelOrigin(center, zoom2) : this.getPixelOrigin();
            return pixelOrigin.subtract(this._getMapPanePos());
          },
          _getNewPixelOrigin: function(center, zoom2) {
            var viewHalf = this.getSize()._divideBy(2);
            return this.project(center, zoom2)._subtract(viewHalf)._add(this._getMapPanePos())._round();
          },
          _latLngToNewLayerPoint: function(latlng, zoom2, center) {
            var topLeft = this._getNewPixelOrigin(center, zoom2);
            return this.project(latlng, zoom2)._subtract(topLeft);
          },
          _latLngBoundsToNewLayerBounds: function(latLngBounds, zoom2, center) {
            var topLeft = this._getNewPixelOrigin(center, zoom2);
            return toBounds([
              this.project(latLngBounds.getSouthWest(), zoom2)._subtract(topLeft),
              this.project(latLngBounds.getNorthWest(), zoom2)._subtract(topLeft),
              this.project(latLngBounds.getSouthEast(), zoom2)._subtract(topLeft),
              this.project(latLngBounds.getNorthEast(), zoom2)._subtract(topLeft)
            ]);
          },
          _getCenterLayerPoint: function() {
            return this.containerPointToLayerPoint(this.getSize()._divideBy(2));
          },
          _getCenterOffset: function(latlng) {
            return this.latLngToLayerPoint(latlng).subtract(this._getCenterLayerPoint());
          },
          _limitCenter: function(center, zoom2, bounds) {
            if (!bounds) {
              return center;
            }
            var centerPoint = this.project(center, zoom2), viewHalf = this.getSize().divideBy(2), viewBounds = new Bounds(centerPoint.subtract(viewHalf), centerPoint.add(viewHalf)), offset = this._getBoundsOffset(viewBounds, bounds, zoom2);
            if (offset.round().equals([0, 0])) {
              return center;
            }
            return this.unproject(centerPoint.add(offset), zoom2);
          },
          _limitOffset: function(offset, bounds) {
            if (!bounds) {
              return offset;
            }
            var viewBounds = this.getPixelBounds(), newBounds = new Bounds(viewBounds.min.add(offset), viewBounds.max.add(offset));
            return offset.add(this._getBoundsOffset(newBounds, bounds));
          },
          _getBoundsOffset: function(pxBounds, maxBounds, zoom2) {
            var projectedMaxBounds = toBounds(
              this.project(maxBounds.getNorthEast(), zoom2),
              this.project(maxBounds.getSouthWest(), zoom2)
            ), minOffset = projectedMaxBounds.min.subtract(pxBounds.min), maxOffset = projectedMaxBounds.max.subtract(pxBounds.max), dx = this._rebound(minOffset.x, -maxOffset.x), dy = this._rebound(minOffset.y, -maxOffset.y);
            return new Point(dx, dy);
          },
          _rebound: function(left, right) {
            return left + right > 0 ? Math.round(left - right) / 2 : Math.max(0, Math.ceil(left)) - Math.max(0, Math.floor(right));
          },
          _limitZoom: function(zoom2) {
            var min = this.getMinZoom(), max = this.getMaxZoom(), snap = Browser.any3d ? this.options.zoomSnap : 1;
            if (snap) {
              zoom2 = Math.round(zoom2 / snap) * snap;
            }
            return Math.max(min, Math.min(max, zoom2));
          },
          _onPanTransitionStep: function() {
            this.fire("move");
          },
          _onPanTransitionEnd: function() {
            removeClass(this._mapPane, "leaflet-pan-anim");
            this.fire("moveend");
          },
          _tryAnimatedPan: function(center, options) {
            var offset = this._getCenterOffset(center)._trunc();
            if ((options && options.animate) !== true && !this.getSize().contains(offset)) {
              return false;
            }
            this.panBy(offset, options);
            return true;
          },
          _createAnimProxy: function() {
            var proxy = this._proxy = create$1("div", "leaflet-proxy leaflet-zoom-animated");
            this._panes.mapPane.appendChild(proxy);
            this.on("zoomanim", function(e) {
              var prop = TRANSFORM, transform = this._proxy.style[prop];
              setTransform(this._proxy, this.project(e.center, e.zoom), this.getZoomScale(e.zoom, 1));
              if (transform === this._proxy.style[prop] && this._animatingZoom) {
                this._onZoomTransitionEnd();
              }
            }, this);
            this.on("load moveend", this._animMoveEnd, this);
            this._on("unload", this._destroyAnimProxy, this);
          },
          _destroyAnimProxy: function() {
            remove(this._proxy);
            this.off("load moveend", this._animMoveEnd, this);
            delete this._proxy;
          },
          _animMoveEnd: function() {
            var c = this.getCenter(), z = this.getZoom();
            setTransform(this._proxy, this.project(c, z), this.getZoomScale(z, 1));
          },
          _catchTransitionEnd: function(e) {
            if (this._animatingZoom && e.propertyName.indexOf("transform") >= 0) {
              this._onZoomTransitionEnd();
            }
          },
          _nothingToAnimate: function() {
            return !this._container.getElementsByClassName("leaflet-zoom-animated").length;
          },
          _tryAnimatedZoom: function(center, zoom2, options) {
            if (this._animatingZoom) {
              return true;
            }
            options = options || {};
            if (!this._zoomAnimated || options.animate === false || this._nothingToAnimate() || Math.abs(zoom2 - this._zoom) > this.options.zoomAnimationThreshold) {
              return false;
            }
            var scale2 = this.getZoomScale(zoom2), offset = this._getCenterOffset(center)._divideBy(1 - 1 / scale2);
            if (options.animate !== true && !this.getSize().contains(offset)) {
              return false;
            }
            requestAnimFrame(function() {
              this._moveStart(true, false)._animateZoom(center, zoom2, true);
            }, this);
            return true;
          },
          _animateZoom: function(center, zoom2, startAnim, noUpdate) {
            if (!this._mapPane) {
              return;
            }
            if (startAnim) {
              this._animatingZoom = true;
              this._animateToCenter = center;
              this._animateToZoom = zoom2;
              addClass(this._mapPane, "leaflet-zoom-anim");
            }
            this.fire("zoomanim", {
              center,
              zoom: zoom2,
              noUpdate
            });
            if (!this._tempFireZoomEvent) {
              this._tempFireZoomEvent = this._zoom !== this._animateToZoom;
            }
            this._move(this._animateToCenter, this._animateToZoom, void 0, true);
            setTimeout(bind(this._onZoomTransitionEnd, this), 250);
          },
          _onZoomTransitionEnd: function() {
            if (!this._animatingZoom) {
              return;
            }
            if (this._mapPane) {
              removeClass(this._mapPane, "leaflet-zoom-anim");
            }
            this._animatingZoom = false;
            this._move(this._animateToCenter, this._animateToZoom, void 0, true);
            if (this._tempFireZoomEvent) {
              this.fire("zoom");
            }
            delete this._tempFireZoomEvent;
            this.fire("move");
            this._moveEnd(true);
          }
        });
        function createMap(id, options) {
          return new Map(id, options);
        }
        var Control = Class.extend({
          options: {
            position: "topright"
          },
          initialize: function(options) {
            setOptions(this, options);
          },
          getPosition: function() {
            return this.options.position;
          },
          setPosition: function(position) {
            var map = this._map;
            if (map) {
              map.removeControl(this);
            }
            this.options.position = position;
            if (map) {
              map.addControl(this);
            }
            return this;
          },
          getContainer: function() {
            return this._container;
          },
          addTo: function(map) {
            this.remove();
            this._map = map;
            var container = this._container = this.onAdd(map), pos = this.getPosition(), corner = map._controlCorners[pos];
            addClass(container, "leaflet-control");
            if (pos.indexOf("bottom") !== -1) {
              corner.insertBefore(container, corner.firstChild);
            } else {
              corner.appendChild(container);
            }
            this._map.on("unload", this.remove, this);
            return this;
          },
          remove: function() {
            if (!this._map) {
              return this;
            }
            remove(this._container);
            if (this.onRemove) {
              this.onRemove(this._map);
            }
            this._map.off("unload", this.remove, this);
            this._map = null;
            return this;
          },
          _refocusOnMap: function(e) {
            if (this._map && e && e.screenX > 0 && e.screenY > 0) {
              this._map.getContainer().focus();
            }
          }
        });
        var control = function(options) {
          return new Control(options);
        };
        Map.include({
          addControl: function(control2) {
            control2.addTo(this);
            return this;
          },
          removeControl: function(control2) {
            control2.remove();
            return this;
          },
          _initControlPos: function() {
            var corners = this._controlCorners = {}, l = "leaflet-", container = this._controlContainer = create$1("div", l + "control-container", this._container);
            function createCorner(vSide, hSide) {
              var className = l + vSide + " " + l + hSide;
              corners[vSide + hSide] = create$1("div", className, container);
            }
            createCorner("top", "left");
            createCorner("top", "right");
            createCorner("bottom", "left");
            createCorner("bottom", "right");
          },
          _clearControlPos: function() {
            for (var i in this._controlCorners) {
              remove(this._controlCorners[i]);
            }
            remove(this._controlContainer);
            delete this._controlCorners;
            delete this._controlContainer;
          }
        });
        var Layers = Control.extend({
          options: {
            collapsed: true,
            position: "topright",
            autoZIndex: true,
            hideSingleBase: false,
            sortLayers: false,
            sortFunction: function(layerA, layerB, nameA, nameB) {
              return nameA < nameB ? -1 : nameB < nameA ? 1 : 0;
            }
          },
          initialize: function(baseLayers, overlays, options) {
            setOptions(this, options);
            this._layerControlInputs = [];
            this._layers = [];
            this._lastZIndex = 0;
            this._handlingClick = false;
            for (var i in baseLayers) {
              this._addLayer(baseLayers[i], i);
            }
            for (i in overlays) {
              this._addLayer(overlays[i], i, true);
            }
          },
          onAdd: function(map) {
            this._initLayout();
            this._update();
            this._map = map;
            map.on("zoomend", this._checkDisabledLayers, this);
            for (var i = 0; i < this._layers.length; i++) {
              this._layers[i].layer.on("add remove", this._onLayerChange, this);
            }
            return this._container;
          },
          addTo: function(map) {
            Control.prototype.addTo.call(this, map);
            return this._expandIfNotCollapsed();
          },
          onRemove: function() {
            this._map.off("zoomend", this._checkDisabledLayers, this);
            for (var i = 0; i < this._layers.length; i++) {
              this._layers[i].layer.off("add remove", this._onLayerChange, this);
            }
          },
          addBaseLayer: function(layer, name) {
            this._addLayer(layer, name);
            return this._map ? this._update() : this;
          },
          addOverlay: function(layer, name) {
            this._addLayer(layer, name, true);
            return this._map ? this._update() : this;
          },
          removeLayer: function(layer) {
            layer.off("add remove", this._onLayerChange, this);
            var obj = this._getLayer(stamp(layer));
            if (obj) {
              this._layers.splice(this._layers.indexOf(obj), 1);
            }
            return this._map ? this._update() : this;
          },
          expand: function() {
            addClass(this._container, "leaflet-control-layers-expanded");
            this._section.style.height = null;
            var acceptableHeight = this._map.getSize().y - (this._container.offsetTop + 50);
            if (acceptableHeight < this._section.clientHeight) {
              addClass(this._section, "leaflet-control-layers-scrollbar");
              this._section.style.height = acceptableHeight + "px";
            } else {
              removeClass(this._section, "leaflet-control-layers-scrollbar");
            }
            this._checkDisabledLayers();
            return this;
          },
          collapse: function() {
            removeClass(this._container, "leaflet-control-layers-expanded");
            return this;
          },
          _initLayout: function() {
            var className = "leaflet-control-layers", container = this._container = create$1("div", className), collapsed = this.options.collapsed;
            container.setAttribute("aria-haspopup", true);
            disableClickPropagation(container);
            disableScrollPropagation(container);
            var section = this._section = create$1("section", className + "-list");
            if (collapsed) {
              this._map.on("click", this.collapse, this);
              on(container, {
                mouseenter: function() {
                  on(section, "click", preventDefault);
                  this.expand();
                  setTimeout(function() {
                    off(section, "click", preventDefault);
                  });
                },
                mouseleave: this.collapse
              }, this);
            }
            var link = this._layersLink = create$1("a", className + "-toggle", container);
            link.href = "#";
            link.title = "Layers";
            link.setAttribute("role", "button");
            on(link, "click", preventDefault);
            on(link, "focus", this.expand, this);
            if (!collapsed) {
              this.expand();
            }
            this._baseLayersList = create$1("div", className + "-base", section);
            this._separator = create$1("div", className + "-separator", section);
            this._overlaysList = create$1("div", className + "-overlays", section);
            container.appendChild(section);
          },
          _getLayer: function(id) {
            for (var i = 0; i < this._layers.length; i++) {
              if (this._layers[i] && stamp(this._layers[i].layer) === id) {
                return this._layers[i];
              }
            }
          },
          _addLayer: function(layer, name, overlay) {
            if (this._map) {
              layer.on("add remove", this._onLayerChange, this);
            }
            this._layers.push({
              layer,
              name,
              overlay
            });
            if (this.options.sortLayers) {
              this._layers.sort(bind(function(a, b) {
                return this.options.sortFunction(a.layer, b.layer, a.name, b.name);
              }, this));
            }
            if (this.options.autoZIndex && layer.setZIndex) {
              this._lastZIndex++;
              layer.setZIndex(this._lastZIndex);
            }
            this._expandIfNotCollapsed();
          },
          _update: function() {
            if (!this._container) {
              return this;
            }
            empty(this._baseLayersList);
            empty(this._overlaysList);
            this._layerControlInputs = [];
            var baseLayersPresent, overlaysPresent, i, obj, baseLayersCount = 0;
            for (i = 0; i < this._layers.length; i++) {
              obj = this._layers[i];
              this._addItem(obj);
              overlaysPresent = overlaysPresent || obj.overlay;
              baseLayersPresent = baseLayersPresent || !obj.overlay;
              baseLayersCount += !obj.overlay ? 1 : 0;
            }
            if (this.options.hideSingleBase) {
              baseLayersPresent = baseLayersPresent && baseLayersCount > 1;
              this._baseLayersList.style.display = baseLayersPresent ? "" : "none";
            }
            this._separator.style.display = overlaysPresent && baseLayersPresent ? "" : "none";
            return this;
          },
          _onLayerChange: function(e) {
            if (!this._handlingClick) {
              this._update();
            }
            var obj = this._getLayer(stamp(e.target));
            var type = obj.overlay ? e.type === "add" ? "overlayadd" : "overlayremove" : e.type === "add" ? "baselayerchange" : null;
            if (type) {
              this._map.fire(type, obj);
            }
          },
          _createRadioElement: function(name, checked) {
            var radioHtml = '<input type="radio" class="leaflet-control-layers-selector" name="' + name + '"' + (checked ? ' checked="checked"' : "") + "/>";
            var radioFragment = document.createElement("div");
            radioFragment.innerHTML = radioHtml;
            return radioFragment.firstChild;
          },
          _addItem: function(obj) {
            var label = document.createElement("label"), checked = this._map.hasLayer(obj.layer), input;
            if (obj.overlay) {
              input = document.createElement("input");
              input.type = "checkbox";
              input.className = "leaflet-control-layers-selector";
              input.defaultChecked = checked;
            } else {
              input = this._createRadioElement("leaflet-base-layers_" + stamp(this), checked);
            }
            this._layerControlInputs.push(input);
            input.layerId = stamp(obj.layer);
            on(input, "click", this._onInputClick, this);
            var name = document.createElement("span");
            name.innerHTML = " " + obj.name;
            var holder = document.createElement("span");
            label.appendChild(holder);
            holder.appendChild(input);
            holder.appendChild(name);
            var container = obj.overlay ? this._overlaysList : this._baseLayersList;
            container.appendChild(label);
            this._checkDisabledLayers();
            return label;
          },
          _onInputClick: function() {
            var inputs = this._layerControlInputs, input, layer;
            var addedLayers = [], removedLayers = [];
            this._handlingClick = true;
            for (var i = inputs.length - 1; i >= 0; i--) {
              input = inputs[i];
              layer = this._getLayer(input.layerId).layer;
              if (input.checked) {
                addedLayers.push(layer);
              } else if (!input.checked) {
                removedLayers.push(layer);
              }
            }
            for (i = 0; i < removedLayers.length; i++) {
              if (this._map.hasLayer(removedLayers[i])) {
                this._map.removeLayer(removedLayers[i]);
              }
            }
            for (i = 0; i < addedLayers.length; i++) {
              if (!this._map.hasLayer(addedLayers[i])) {
                this._map.addLayer(addedLayers[i]);
              }
            }
            this._handlingClick = false;
            this._refocusOnMap();
          },
          _checkDisabledLayers: function() {
            var inputs = this._layerControlInputs, input, layer, zoom2 = this._map.getZoom();
            for (var i = inputs.length - 1; i >= 0; i--) {
              input = inputs[i];
              layer = this._getLayer(input.layerId).layer;
              input.disabled = layer.options.minZoom !== void 0 && zoom2 < layer.options.minZoom || layer.options.maxZoom !== void 0 && zoom2 > layer.options.maxZoom;
            }
          },
          _expandIfNotCollapsed: function() {
            if (this._map && !this.options.collapsed) {
              this.expand();
            }
            return this;
          }
        });
        var layers = function(baseLayers, overlays, options) {
          return new Layers(baseLayers, overlays, options);
        };
        var Zoom = Control.extend({
          options: {
            position: "topleft",
            zoomInText: '<span aria-hidden="true">+</span>',
            zoomInTitle: "Zoom in",
            zoomOutText: '<span aria-hidden="true">&#x2212;</span>',
            zoomOutTitle: "Zoom out"
          },
          onAdd: function(map) {
            var zoomName = "leaflet-control-zoom", container = create$1("div", zoomName + " leaflet-bar"), options = this.options;
            this._zoomInButton = this._createButton(
              options.zoomInText,
              options.zoomInTitle,
              zoomName + "-in",
              container,
              this._zoomIn
            );
            this._zoomOutButton = this._createButton(
              options.zoomOutText,
              options.zoomOutTitle,
              zoomName + "-out",
              container,
              this._zoomOut
            );
            this._updateDisabled();
            map.on("zoomend zoomlevelschange", this._updateDisabled, this);
            return container;
          },
          onRemove: function(map) {
            map.off("zoomend zoomlevelschange", this._updateDisabled, this);
          },
          disable: function() {
            this._disabled = true;
            this._updateDisabled();
            return this;
          },
          enable: function() {
            this._disabled = false;
            this._updateDisabled();
            return this;
          },
          _zoomIn: function(e) {
            if (!this._disabled && this._map._zoom < this._map.getMaxZoom()) {
              this._map.zoomIn(this._map.options.zoomDelta * (e.shiftKey ? 3 : 1));
            }
          },
          _zoomOut: function(e) {
            if (!this._disabled && this._map._zoom > this._map.getMinZoom()) {
              this._map.zoomOut(this._map.options.zoomDelta * (e.shiftKey ? 3 : 1));
            }
          },
          _createButton: function(html, title, className, container, fn) {
            var link = create$1("a", className, container);
            link.innerHTML = html;
            link.href = "#";
            link.title = title;
            link.setAttribute("role", "button");
            link.setAttribute("aria-label", title);
            disableClickPropagation(link);
            on(link, "click", stop);
            on(link, "click", fn, this);
            on(link, "click", this._refocusOnMap, this);
            return link;
          },
          _updateDisabled: function() {
            var map = this._map, className = "leaflet-disabled";
            removeClass(this._zoomInButton, className);
            removeClass(this._zoomOutButton, className);
            this._zoomInButton.setAttribute("aria-disabled", "false");
            this._zoomOutButton.setAttribute("aria-disabled", "false");
            if (this._disabled || map._zoom === map.getMinZoom()) {
              addClass(this._zoomOutButton, className);
              this._zoomOutButton.setAttribute("aria-disabled", "true");
            }
            if (this._disabled || map._zoom === map.getMaxZoom()) {
              addClass(this._zoomInButton, className);
              this._zoomInButton.setAttribute("aria-disabled", "true");
            }
          }
        });
        Map.mergeOptions({
          zoomControl: true
        });
        Map.addInitHook(function() {
          if (this.options.zoomControl) {
            this.zoomControl = new Zoom();
            this.addControl(this.zoomControl);
          }
        });
        var zoom = function(options) {
          return new Zoom(options);
        };
        var Scale = Control.extend({
          options: {
            position: "bottomleft",
            maxWidth: 100,
            metric: true,
            imperial: true
          },
          onAdd: function(map) {
            var className = "leaflet-control-scale", container = create$1("div", className), options = this.options;
            this._addScales(options, className + "-line", container);
            map.on(options.updateWhenIdle ? "moveend" : "move", this._update, this);
            map.whenReady(this._update, this);
            return container;
          },
          onRemove: function(map) {
            map.off(this.options.updateWhenIdle ? "moveend" : "move", this._update, this);
          },
          _addScales: function(options, className, container) {
            if (options.metric) {
              this._mScale = create$1("div", className, container);
            }
            if (options.imperial) {
              this._iScale = create$1("div", className, container);
            }
          },
          _update: function() {
            var map = this._map, y = map.getSize().y / 2;
            var maxMeters = map.distance(
              map.containerPointToLatLng([0, y]),
              map.containerPointToLatLng([this.options.maxWidth, y])
            );
            this._updateScales(maxMeters);
          },
          _updateScales: function(maxMeters) {
            if (this.options.metric && maxMeters) {
              this._updateMetric(maxMeters);
            }
            if (this.options.imperial && maxMeters) {
              this._updateImperial(maxMeters);
            }
          },
          _updateMetric: function(maxMeters) {
            var meters = this._getRoundNum(maxMeters), label = meters < 1e3 ? meters + " m" : meters / 1e3 + " km";
            this._updateScale(this._mScale, label, meters / maxMeters);
          },
          _updateImperial: function(maxMeters) {
            var maxFeet = maxMeters * 3.2808399, maxMiles, miles, feet;
            if (maxFeet > 5280) {
              maxMiles = maxFeet / 5280;
              miles = this._getRoundNum(maxMiles);
              this._updateScale(this._iScale, miles + " mi", miles / maxMiles);
            } else {
              feet = this._getRoundNum(maxFeet);
              this._updateScale(this._iScale, feet + " ft", feet / maxFeet);
            }
          },
          _updateScale: function(scale2, text, ratio) {
            scale2.style.width = Math.round(this.options.maxWidth * ratio) + "px";
            scale2.innerHTML = text;
          },
          _getRoundNum: function(num) {
            var pow10 = Math.pow(10, (Math.floor(num) + "").length - 1), d = num / pow10;
            d = d >= 10 ? 10 : d >= 5 ? 5 : d >= 3 ? 3 : d >= 2 ? 2 : 1;
            return pow10 * d;
          }
        });
        var scale = function(options) {
          return new Scale(options);
        };
        var ukrainianFlag = '<svg aria-hidden="true" xmlns="http://www.w3.org/2000/svg" width="12" height="8"><path fill="#4C7BE1" d="M0 0h12v4H0z"/><path fill="#FFD500" d="M0 4h12v3H0z"/><path fill="#E0BC00" d="M0 7h12v1H0z"/></svg>';
        var Attribution = Control.extend({
          options: {
            position: "bottomright",
            prefix: '<a href="https://leafletjs.com" title="A JavaScript library for interactive maps">' + (Browser.inlineSvg ? ukrainianFlag + " " : "") + "Leaflet</a>"
          },
          initialize: function(options) {
            setOptions(this, options);
            this._attributions = {};
          },
          onAdd: function(map) {
            map.attributionControl = this;
            this._container = create$1("div", "leaflet-control-attribution");
            disableClickPropagation(this._container);
            for (var i in map._layers) {
              if (map._layers[i].getAttribution) {
                this.addAttribution(map._layers[i].getAttribution());
              }
            }
            this._update();
            map.on("layeradd", this._addAttribution, this);
            return this._container;
          },
          onRemove: function(map) {
            map.off("layeradd", this._addAttribution, this);
          },
          _addAttribution: function(ev) {
            if (ev.layer.getAttribution) {
              this.addAttribution(ev.layer.getAttribution());
              ev.layer.once("remove", function() {
                this.removeAttribution(ev.layer.getAttribution());
              }, this);
            }
          },
          setPrefix: function(prefix) {
            this.options.prefix = prefix;
            this._update();
            return this;
          },
          addAttribution: function(text) {
            if (!text) {
              return this;
            }
            if (!this._attributions[text]) {
              this._attributions[text] = 0;
            }
            this._attributions[text]++;
            this._update();
            return this;
          },
          removeAttribution: function(text) {
            if (!text) {
              return this;
            }
            if (this._attributions[text]) {
              this._attributions[text]--;
              this._update();
            }
            return this;
          },
          _update: function() {
            if (!this._map) {
              return;
            }
            var attribs = [];
            for (var i in this._attributions) {
              if (this._attributions[i]) {
                attribs.push(i);
              }
            }
            var prefixAndAttribs = [];
            if (this.options.prefix) {
              prefixAndAttribs.push(this.options.prefix);
            }
            if (attribs.length) {
              prefixAndAttribs.push(attribs.join(", "));
            }
            this._container.innerHTML = prefixAndAttribs.join(' <span aria-hidden="true">|</span> ');
          }
        });
        Map.mergeOptions({
          attributionControl: true
        });
        Map.addInitHook(function() {
          if (this.options.attributionControl) {
            new Attribution().addTo(this);
          }
        });
        var attribution = function(options) {
          return new Attribution(options);
        };
        Control.Layers = Layers;
        Control.Zoom = Zoom;
        Control.Scale = Scale;
        Control.Attribution = Attribution;
        control.layers = layers;
        control.zoom = zoom;
        control.scale = scale;
        control.attribution = attribution;
        var Handler = Class.extend({
          initialize: function(map) {
            this._map = map;
          },
          enable: function() {
            if (this._enabled) {
              return this;
            }
            this._enabled = true;
            this.addHooks();
            return this;
          },
          disable: function() {
            if (!this._enabled) {
              return this;
            }
            this._enabled = false;
            this.removeHooks();
            return this;
          },
          enabled: function() {
            return !!this._enabled;
          }
        });
        Handler.addTo = function(map, name) {
          map.addHandler(name, this);
          return this;
        };
        var Mixin = { Events };
        var START = Browser.touch ? "touchstart mousedown" : "mousedown";
        var Draggable = Evented.extend({
          options: {
            clickTolerance: 3
          },
          initialize: function(element, dragStartTarget, preventOutline2, options) {
            setOptions(this, options);
            this._element = element;
            this._dragStartTarget = dragStartTarget || element;
            this._preventOutline = preventOutline2;
          },
          enable: function() {
            if (this._enabled) {
              return;
            }
            on(this._dragStartTarget, START, this._onDown, this);
            this._enabled = true;
          },
          disable: function() {
            if (!this._enabled) {
              return;
            }
            if (Draggable._dragging === this) {
              this.finishDrag(true);
            }
            off(this._dragStartTarget, START, this._onDown, this);
            this._enabled = false;
            this._moved = false;
          },
          _onDown: function(e) {
            if (!this._enabled) {
              return;
            }
            this._moved = false;
            if (hasClass(this._element, "leaflet-zoom-anim")) {
              return;
            }
            if (e.touches && e.touches.length !== 1) {
              if (Draggable._dragging === this) {
                this.finishDrag();
              }
              return;
            }
            if (Draggable._dragging || e.shiftKey || e.which !== 1 && e.button !== 1 && !e.touches) {
              return;
            }
            Draggable._dragging = this;
            if (this._preventOutline) {
              preventOutline(this._element);
            }
            disableImageDrag();
            disableTextSelection();
            if (this._moving) {
              return;
            }
            this.fire("down");
            var first = e.touches ? e.touches[0] : e, sizedParent = getSizedParentNode(this._element);
            this._startPoint = new Point(first.clientX, first.clientY);
            this._startPos = getPosition(this._element);
            this._parentScale = getScale(sizedParent);
            var mouseevent = e.type === "mousedown";
            on(document, mouseevent ? "mousemove" : "touchmove", this._onMove, this);
            on(document, mouseevent ? "mouseup" : "touchend touchcancel", this._onUp, this);
          },
          _onMove: function(e) {
            if (!this._enabled) {
              return;
            }
            if (e.touches && e.touches.length > 1) {
              this._moved = true;
              return;
            }
            var first = e.touches && e.touches.length === 1 ? e.touches[0] : e, offset = new Point(first.clientX, first.clientY)._subtract(this._startPoint);
            if (!offset.x && !offset.y) {
              return;
            }
            if (Math.abs(offset.x) + Math.abs(offset.y) < this.options.clickTolerance) {
              return;
            }
            offset.x /= this._parentScale.x;
            offset.y /= this._parentScale.y;
            preventDefault(e);
            if (!this._moved) {
              this.fire("dragstart");
              this._moved = true;
              addClass(document.body, "leaflet-dragging");
              this._lastTarget = e.target || e.srcElement;
              if (window.SVGElementInstance && this._lastTarget instanceof window.SVGElementInstance) {
                this._lastTarget = this._lastTarget.correspondingUseElement;
              }
              addClass(this._lastTarget, "leaflet-drag-target");
            }
            this._newPos = this._startPos.add(offset);
            this._moving = true;
            this._lastEvent = e;
            this._updatePosition();
          },
          _updatePosition: function() {
            var e = { originalEvent: this._lastEvent };
            this.fire("predrag", e);
            setPosition(this._element, this._newPos);
            this.fire("drag", e);
          },
          _onUp: function() {
            if (!this._enabled) {
              return;
            }
            this.finishDrag();
          },
          finishDrag: function(noInertia) {
            removeClass(document.body, "leaflet-dragging");
            if (this._lastTarget) {
              removeClass(this._lastTarget, "leaflet-drag-target");
              this._lastTarget = null;
            }
            off(document, "mousemove touchmove", this._onMove, this);
            off(document, "mouseup touchend touchcancel", this._onUp, this);
            enableImageDrag();
            enableTextSelection();
            if (this._moved && this._moving) {
              this.fire("dragend", {
                noInertia,
                distance: this._newPos.distanceTo(this._startPos)
              });
            }
            this._moving = false;
            Draggable._dragging = false;
          }
        });
        function simplify(points, tolerance) {
          if (!tolerance || !points.length) {
            return points.slice();
          }
          var sqTolerance = tolerance * tolerance;
          points = _reducePoints(points, sqTolerance);
          points = _simplifyDP(points, sqTolerance);
          return points;
        }
        function pointToSegmentDistance(p, p1, p2) {
          return Math.sqrt(_sqClosestPointOnSegment(p, p1, p2, true));
        }
        function closestPointOnSegment(p, p1, p2) {
          return _sqClosestPointOnSegment(p, p1, p2);
        }
        function _simplifyDP(points, sqTolerance) {
          var len = points.length, ArrayConstructor = typeof Uint8Array !== void 0 + "" ? Uint8Array : Array, markers = new ArrayConstructor(len);
          markers[0] = markers[len - 1] = 1;
          _simplifyDPStep(points, markers, sqTolerance, 0, len - 1);
          var i, newPoints = [];
          for (i = 0; i < len; i++) {
            if (markers[i]) {
              newPoints.push(points[i]);
            }
          }
          return newPoints;
        }
        function _simplifyDPStep(points, markers, sqTolerance, first, last) {
          var maxSqDist = 0, index2, i, sqDist;
          for (i = first + 1; i <= last - 1; i++) {
            sqDist = _sqClosestPointOnSegment(points[i], points[first], points[last], true);
            if (sqDist > maxSqDist) {
              index2 = i;
              maxSqDist = sqDist;
            }
          }
          if (maxSqDist > sqTolerance) {
            markers[index2] = 1;
            _simplifyDPStep(points, markers, sqTolerance, first, index2);
            _simplifyDPStep(points, markers, sqTolerance, index2, last);
          }
        }
        function _reducePoints(points, sqTolerance) {
          var reducedPoints = [points[0]];
          for (var i = 1, prev = 0, len = points.length; i < len; i++) {
            if (_sqDist(points[i], points[prev]) > sqTolerance) {
              reducedPoints.push(points[i]);
              prev = i;
            }
          }
          if (prev < len - 1) {
            reducedPoints.push(points[len - 1]);
          }
          return reducedPoints;
        }
        var _lastCode;
        function clipSegment(a, b, bounds, useLastCode, round) {
          var codeA = useLastCode ? _lastCode : _getBitCode(a, bounds), codeB = _getBitCode(b, bounds), codeOut, p, newCode;
          _lastCode = codeB;
          while (true) {
            if (!(codeA | codeB)) {
              return [a, b];
            }
            if (codeA & codeB) {
              return false;
            }
            codeOut = codeA || codeB;
            p = _getEdgeIntersection(a, b, codeOut, bounds, round);
            newCode = _getBitCode(p, bounds);
            if (codeOut === codeA) {
              a = p;
              codeA = newCode;
            } else {
              b = p;
              codeB = newCode;
            }
          }
        }
        function _getEdgeIntersection(a, b, code, bounds, round) {
          var dx = b.x - a.x, dy = b.y - a.y, min = bounds.min, max = bounds.max, x, y;
          if (code & 8) {
            x = a.x + dx * (max.y - a.y) / dy;
            y = max.y;
          } else if (code & 4) {
            x = a.x + dx * (min.y - a.y) / dy;
            y = min.y;
          } else if (code & 2) {
            x = max.x;
            y = a.y + dy * (max.x - a.x) / dx;
          } else if (code & 1) {
            x = min.x;
            y = a.y + dy * (min.x - a.x) / dx;
          }
          return new Point(x, y, round);
        }
        function _getBitCode(p, bounds) {
          var code = 0;
          if (p.x < bounds.min.x) {
            code |= 1;
          } else if (p.x > bounds.max.x) {
            code |= 2;
          }
          if (p.y < bounds.min.y) {
            code |= 4;
          } else if (p.y > bounds.max.y) {
            code |= 8;
          }
          return code;
        }
        function _sqDist(p1, p2) {
          var dx = p2.x - p1.x, dy = p2.y - p1.y;
          return dx * dx + dy * dy;
        }
        function _sqClosestPointOnSegment(p, p1, p2, sqDist) {
          var x = p1.x, y = p1.y, dx = p2.x - x, dy = p2.y - y, dot = dx * dx + dy * dy, t;
          if (dot > 0) {
            t = ((p.x - x) * dx + (p.y - y) * dy) / dot;
            if (t > 1) {
              x = p2.x;
              y = p2.y;
            } else if (t > 0) {
              x += dx * t;
              y += dy * t;
            }
          }
          dx = p.x - x;
          dy = p.y - y;
          return sqDist ? dx * dx + dy * dy : new Point(x, y);
        }
        function isFlat(latlngs) {
          return !isArray(latlngs[0]) || typeof latlngs[0][0] !== "object" && typeof latlngs[0][0] !== "undefined";
        }
        function _flat(latlngs) {
          console.warn("Deprecated use of _flat, please use L.LineUtil.isFlat instead.");
          return isFlat(latlngs);
        }
        var LineUtil = {
          __proto__: null,
          simplify,
          pointToSegmentDistance,
          closestPointOnSegment,
          clipSegment,
          _getEdgeIntersection,
          _getBitCode,
          _sqClosestPointOnSegment,
          isFlat,
          _flat
        };
        function clipPolygon(points, bounds, round) {
          var clippedPoints, edges = [1, 4, 2, 8], i, j, k, a, b, len, edge2, p;
          for (i = 0, len = points.length; i < len; i++) {
            points[i]._code = _getBitCode(points[i], bounds);
          }
          for (k = 0; k < 4; k++) {
            edge2 = edges[k];
            clippedPoints = [];
            for (i = 0, len = points.length, j = len - 1; i < len; j = i++) {
              a = points[i];
              b = points[j];
              if (!(a._code & edge2)) {
                if (b._code & edge2) {
                  p = _getEdgeIntersection(b, a, edge2, bounds, round);
                  p._code = _getBitCode(p, bounds);
                  clippedPoints.push(p);
                }
                clippedPoints.push(a);
              } else if (!(b._code & edge2)) {
                p = _getEdgeIntersection(b, a, edge2, bounds, round);
                p._code = _getBitCode(p, bounds);
                clippedPoints.push(p);
              }
            }
            points = clippedPoints;
          }
          return points;
        }
        var PolyUtil = {
          __proto__: null,
          clipPolygon
        };
        var LonLat = {
          project: function(latlng) {
            return new Point(latlng.lng, latlng.lat);
          },
          unproject: function(point) {
            return new LatLng(point.y, point.x);
          },
          bounds: new Bounds([-180, -90], [180, 90])
        };
        var Mercator = {
          R: 6378137,
          R_MINOR: 6356752314245179e-9,
          bounds: new Bounds([-2003750834279e-5, -1549657073972e-5], [2003750834279e-5, 1876465623138e-5]),
          project: function(latlng) {
            var d = Math.PI / 180, r = this.R, y = latlng.lat * d, tmp = this.R_MINOR / r, e = Math.sqrt(1 - tmp * tmp), con = e * Math.sin(y);
            var ts = Math.tan(Math.PI / 4 - y / 2) / Math.pow((1 - con) / (1 + con), e / 2);
            y = -r * Math.log(Math.max(ts, 1e-10));
            return new Point(latlng.lng * d * r, y);
          },
          unproject: function(point) {
            var d = 180 / Math.PI, r = this.R, tmp = this.R_MINOR / r, e = Math.sqrt(1 - tmp * tmp), ts = Math.exp(-point.y / r), phi = Math.PI / 2 - 2 * Math.atan(ts);
            for (var i = 0, dphi = 0.1, con; i < 15 && Math.abs(dphi) > 1e-7; i++) {
              con = e * Math.sin(phi);
              con = Math.pow((1 - con) / (1 + con), e / 2);
              dphi = Math.PI / 2 - 2 * Math.atan(ts * con) - phi;
              phi += dphi;
            }
            return new LatLng(phi * d, point.x * d / r);
          }
        };
        var index = {
          __proto__: null,
          LonLat,
          Mercator,
          SphericalMercator
        };
        var EPSG3395 = extend({}, Earth, {
          code: "EPSG:3395",
          projection: Mercator,
          transformation: function() {
            var scale2 = 0.5 / (Math.PI * Mercator.R);
            return toTransformation(scale2, 0.5, -scale2, 0.5);
          }()
        });
        var EPSG4326 = extend({}, Earth, {
          code: "EPSG:4326",
          projection: LonLat,
          transformation: toTransformation(1 / 180, 1, -1 / 180, 0.5)
        });
        var Simple = extend({}, CRS, {
          projection: LonLat,
          transformation: toTransformation(1, 0, -1, 0),
          scale: function(zoom2) {
            return Math.pow(2, zoom2);
          },
          zoom: function(scale2) {
            return Math.log(scale2) / Math.LN2;
          },
          distance: function(latlng1, latlng2) {
            var dx = latlng2.lng - latlng1.lng, dy = latlng2.lat - latlng1.lat;
            return Math.sqrt(dx * dx + dy * dy);
          },
          infinite: true
        });
        CRS.Earth = Earth;
        CRS.EPSG3395 = EPSG3395;
        CRS.EPSG3857 = EPSG3857;
        CRS.EPSG900913 = EPSG900913;
        CRS.EPSG4326 = EPSG4326;
        CRS.Simple = Simple;
        var Layer = Evented.extend({
          options: {
            pane: "overlayPane",
            attribution: null,
            bubblingMouseEvents: true
          },
          addTo: function(map) {
            map.addLayer(this);
            return this;
          },
          remove: function() {
            return this.removeFrom(this._map || this._mapToAdd);
          },
          removeFrom: function(obj) {
            if (obj) {
              obj.removeLayer(this);
            }
            return this;
          },
          getPane: function(name) {
            return this._map.getPane(name ? this.options[name] || name : this.options.pane);
          },
          addInteractiveTarget: function(targetEl) {
            this._map._targets[stamp(targetEl)] = this;
            return this;
          },
          removeInteractiveTarget: function(targetEl) {
            delete this._map._targets[stamp(targetEl)];
            return this;
          },
          getAttribution: function() {
            return this.options.attribution;
          },
          _layerAdd: function(e) {
            var map = e.target;
            if (!map.hasLayer(this)) {
              return;
            }
            this._map = map;
            this._zoomAnimated = map._zoomAnimated;
            if (this.getEvents) {
              var events = this.getEvents();
              map.on(events, this);
              this.once("remove", function() {
                map.off(events, this);
              }, this);
            }
            this.onAdd(map);
            this.fire("add");
            map.fire("layeradd", { layer: this });
          }
        });
        Map.include({
          addLayer: function(layer) {
            if (!layer._layerAdd) {
              throw new Error("The provided object is not a Layer.");
            }
            var id = stamp(layer);
            if (this._layers[id]) {
              return this;
            }
            this._layers[id] = layer;
            layer._mapToAdd = this;
            if (layer.beforeAdd) {
              layer.beforeAdd(this);
            }
            this.whenReady(layer._layerAdd, layer);
            return this;
          },
          removeLayer: function(layer) {
            var id = stamp(layer);
            if (!this._layers[id]) {
              return this;
            }
            if (this._loaded) {
              layer.onRemove(this);
            }
            delete this._layers[id];
            if (this._loaded) {
              this.fire("layerremove", { layer });
              layer.fire("remove");
            }
            layer._map = layer._mapToAdd = null;
            return this;
          },
          hasLayer: function(layer) {
            return stamp(layer) in this._layers;
          },
          eachLayer: function(method, context) {
            for (var i in this._layers) {
              method.call(context, this._layers[i]);
            }
            return this;
          },
          _addLayers: function(layers2) {
            layers2 = layers2 ? isArray(layers2) ? layers2 : [layers2] : [];
            for (var i = 0, len = layers2.length; i < len; i++) {
              this.addLayer(layers2[i]);
            }
          },
          _addZoomLimit: function(layer) {
            if (!isNaN(layer.options.maxZoom) || !isNaN(layer.options.minZoom)) {
              this._zoomBoundLayers[stamp(layer)] = layer;
              this._updateZoomLevels();
            }
          },
          _removeZoomLimit: function(layer) {
            var id = stamp(layer);
            if (this._zoomBoundLayers[id]) {
              delete this._zoomBoundLayers[id];
              this._updateZoomLevels();
            }
          },
          _updateZoomLevels: function() {
            var minZoom = Infinity, maxZoom = -Infinity, oldZoomSpan = this._getZoomSpan();
            for (var i in this._zoomBoundLayers) {
              var options = this._zoomBoundLayers[i].options;
              minZoom = options.minZoom === void 0 ? minZoom : Math.min(minZoom, options.minZoom);
              maxZoom = options.maxZoom === void 0 ? maxZoom : Math.max(maxZoom, options.maxZoom);
            }
            this._layersMaxZoom = maxZoom === -Infinity ? void 0 : maxZoom;
            this._layersMinZoom = minZoom === Infinity ? void 0 : minZoom;
            if (oldZoomSpan !== this._getZoomSpan()) {
              this.fire("zoomlevelschange");
            }
            if (this.options.maxZoom === void 0 && this._layersMaxZoom && this.getZoom() > this._layersMaxZoom) {
              this.setZoom(this._layersMaxZoom);
            }
            if (this.options.minZoom === void 0 && this._layersMinZoom && this.getZoom() < this._layersMinZoom) {
              this.setZoom(this._layersMinZoom);
            }
          }
        });
        var LayerGroup = Layer.extend({
          initialize: function(layers2, options) {
            setOptions(this, options);
            this._layers = {};
            var i, len;
            if (layers2) {
              for (i = 0, len = layers2.length; i < len; i++) {
                this.addLayer(layers2[i]);
              }
            }
          },
          addLayer: function(layer) {
            var id = this.getLayerId(layer);
            this._layers[id] = layer;
            if (this._map) {
              this._map.addLayer(layer);
            }
            return this;
          },
          removeLayer: function(layer) {
            var id = layer in this._layers ? layer : this.getLayerId(layer);
            if (this._map && this._layers[id]) {
              this._map.removeLayer(this._layers[id]);
            }
            delete this._layers[id];
            return this;
          },
          hasLayer: function(layer) {
            var layerId = typeof layer === "number" ? layer : this.getLayerId(layer);
            return layerId in this._layers;
          },
          clearLayers: function() {
            return this.eachLayer(this.removeLayer, this);
          },
          invoke: function(methodName) {
            var args = Array.prototype.slice.call(arguments, 1), i, layer;
            for (i in this._layers) {
              layer = this._layers[i];
              if (layer[methodName]) {
                layer[methodName].apply(layer, args);
              }
            }
            return this;
          },
          onAdd: function(map) {
            this.eachLayer(map.addLayer, map);
          },
          onRemove: function(map) {
            this.eachLayer(map.removeLayer, map);
          },
          eachLayer: function(method, context) {
            for (var i in this._layers) {
              method.call(context, this._layers[i]);
            }
            return this;
          },
          getLayer: function(id) {
            return this._layers[id];
          },
          getLayers: function() {
            var layers2 = [];
            this.eachLayer(layers2.push, layers2);
            return layers2;
          },
          setZIndex: function(zIndex) {
            return this.invoke("setZIndex", zIndex);
          },
          getLayerId: function(layer) {
            return stamp(layer);
          }
        });
        var layerGroup = function(layers2, options) {
          return new LayerGroup(layers2, options);
        };
        var FeatureGroup = LayerGroup.extend({
          addLayer: function(layer) {
            if (this.hasLayer(layer)) {
              return this;
            }
            layer.addEventParent(this);
            LayerGroup.prototype.addLayer.call(this, layer);
            return this.fire("layeradd", { layer });
          },
          removeLayer: function(layer) {
            if (!this.hasLayer(layer)) {
              return this;
            }
            if (layer in this._layers) {
              layer = this._layers[layer];
            }
            layer.removeEventParent(this);
            LayerGroup.prototype.removeLayer.call(this, layer);
            return this.fire("layerremove", { layer });
          },
          setStyle: function(style2) {
            return this.invoke("setStyle", style2);
          },
          bringToFront: function() {
            return this.invoke("bringToFront");
          },
          bringToBack: function() {
            return this.invoke("bringToBack");
          },
          getBounds: function() {
            var bounds = new LatLngBounds();
            for (var id in this._layers) {
              var layer = this._layers[id];
              bounds.extend(layer.getBounds ? layer.getBounds() : layer.getLatLng());
            }
            return bounds;
          }
        });
        var featureGroup = function(layers2, options) {
          return new FeatureGroup(layers2, options);
        };
        var Icon = Class.extend({
          options: {
            popupAnchor: [0, 0],
            tooltipAnchor: [0, 0],
            crossOrigin: false
          },
          initialize: function(options) {
            setOptions(this, options);
          },
          createIcon: function(oldIcon) {
            return this._createIcon("icon", oldIcon);
          },
          createShadow: function(oldIcon) {
            return this._createIcon("shadow", oldIcon);
          },
          _createIcon: function(name, oldIcon) {
            var src = this._getIconUrl(name);
            if (!src) {
              if (name === "icon") {
                throw new Error("iconUrl not set in Icon options (see the docs).");
              }
              return null;
            }
            var img = this._createImg(src, oldIcon && oldIcon.tagName === "IMG" ? oldIcon : null);
            this._setIconStyles(img, name);
            if (this.options.crossOrigin || this.options.crossOrigin === "") {
              img.crossOrigin = this.options.crossOrigin === true ? "" : this.options.crossOrigin;
            }
            return img;
          },
          _setIconStyles: function(img, name) {
            var options = this.options;
            var sizeOption = options[name + "Size"];
            if (typeof sizeOption === "number") {
              sizeOption = [sizeOption, sizeOption];
            }
            var size = toPoint(sizeOption), anchor = toPoint(name === "shadow" && options.shadowAnchor || options.iconAnchor || size && size.divideBy(2, true));
            img.className = "leaflet-marker-" + name + " " + (options.className || "");
            if (anchor) {
              img.style.marginLeft = -anchor.x + "px";
              img.style.marginTop = -anchor.y + "px";
            }
            if (size) {
              img.style.width = size.x + "px";
              img.style.height = size.y + "px";
            }
          },
          _createImg: function(src, el) {
            el = el || document.createElement("img");
            el.src = src;
            return el;
          },
          _getIconUrl: function(name) {
            return Browser.retina && this.options[name + "RetinaUrl"] || this.options[name + "Url"];
          }
        });
        function icon(options) {
          return new Icon(options);
        }
        var IconDefault = Icon.extend({
          options: {
            iconUrl: "marker-icon.png",
            iconRetinaUrl: "marker-icon-2x.png",
            shadowUrl: "marker-shadow.png",
            iconSize: [25, 41],
            iconAnchor: [12, 41],
            popupAnchor: [1, -34],
            tooltipAnchor: [16, -28],
            shadowSize: [41, 41]
          },
          _getIconUrl: function(name) {
            if (typeof IconDefault.imagePath !== "string") {
              IconDefault.imagePath = this._detectIconPath();
            }
            return (this.options.imagePath || IconDefault.imagePath) + Icon.prototype._getIconUrl.call(this, name);
          },
          _stripUrl: function(path) {
            var strip = function(str, re, idx) {
              var match = re.exec(str);
              return match && match[idx];
            };
            path = strip(path, /^url\((['"])?(.+)\1\)$/, 2);
            return path && strip(path, /^(.*)marker-icon\.png$/, 1);
          },
          _detectIconPath: function() {
            var el = create$1("div", "leaflet-default-icon-path", document.body);
            var path = getStyle(el, "background-image") || getStyle(el, "backgroundImage");
            document.body.removeChild(el);
            path = this._stripUrl(path);
            if (path) {
              return path;
            }
            var link = document.querySelector('link[href$="leaflet.css"]');
            if (!link) {
              return "";
            }
            return link.href.substring(0, link.href.length - "leaflet.css".length - 1);
          }
        });
        var MarkerDrag = Handler.extend({
          initialize: function(marker2) {
            this._marker = marker2;
          },
          addHooks: function() {
            var icon2 = this._marker._icon;
            if (!this._draggable) {
              this._draggable = new Draggable(icon2, icon2, true);
            }
            this._draggable.on({
              dragstart: this._onDragStart,
              predrag: this._onPreDrag,
              drag: this._onDrag,
              dragend: this._onDragEnd
            }, this).enable();
            addClass(icon2, "leaflet-marker-draggable");
          },
          removeHooks: function() {
            this._draggable.off({
              dragstart: this._onDragStart,
              predrag: this._onPreDrag,
              drag: this._onDrag,
              dragend: this._onDragEnd
            }, this).disable();
            if (this._marker._icon) {
              removeClass(this._marker._icon, "leaflet-marker-draggable");
            }
          },
          moved: function() {
            return this._draggable && this._draggable._moved;
          },
          _adjustPan: function(e) {
            var marker2 = this._marker, map = marker2._map, speed = this._marker.options.autoPanSpeed, padding = this._marker.options.autoPanPadding, iconPos = getPosition(marker2._icon), bounds = map.getPixelBounds(), origin = map.getPixelOrigin();
            var panBounds = toBounds(
              bounds.min._subtract(origin).add(padding),
              bounds.max._subtract(origin).subtract(padding)
            );
            if (!panBounds.contains(iconPos)) {
              var movement = toPoint(
                (Math.max(panBounds.max.x, iconPos.x) - panBounds.max.x) / (bounds.max.x - panBounds.max.x) - (Math.min(panBounds.min.x, iconPos.x) - panBounds.min.x) / (bounds.min.x - panBounds.min.x),
                (Math.max(panBounds.max.y, iconPos.y) - panBounds.max.y) / (bounds.max.y - panBounds.max.y) - (Math.min(panBounds.min.y, iconPos.y) - panBounds.min.y) / (bounds.min.y - panBounds.min.y)
              ).multiplyBy(speed);
              map.panBy(movement, { animate: false });
              this._draggable._newPos._add(movement);
              this._draggable._startPos._add(movement);
              setPosition(marker2._icon, this._draggable._newPos);
              this._onDrag(e);
              this._panRequest = requestAnimFrame(this._adjustPan.bind(this, e));
            }
          },
          _onDragStart: function() {
            this._oldLatLng = this._marker.getLatLng();
            this._marker.closePopup && this._marker.closePopup();
            this._marker.fire("movestart").fire("dragstart");
          },
          _onPreDrag: function(e) {
            if (this._marker.options.autoPan) {
              cancelAnimFrame(this._panRequest);
              this._panRequest = requestAnimFrame(this._adjustPan.bind(this, e));
            }
          },
          _onDrag: function(e) {
            var marker2 = this._marker, shadow = marker2._shadow, iconPos = getPosition(marker2._icon), latlng = marker2._map.layerPointToLatLng(iconPos);
            if (shadow) {
              setPosition(shadow, iconPos);
            }
            marker2._latlng = latlng;
            e.latlng = latlng;
            e.oldLatLng = this._oldLatLng;
            marker2.fire("move", e).fire("drag", e);
          },
          _onDragEnd: function(e) {
            cancelAnimFrame(this._panRequest);
            delete this._oldLatLng;
            this._marker.fire("moveend").fire("dragend", e);
          }
        });
        var Marker = Layer.extend({
          options: {
            icon: new IconDefault(),
            interactive: true,
            keyboard: true,
            title: "",
            alt: "Marker",
            zIndexOffset: 0,
            opacity: 1,
            riseOnHover: false,
            riseOffset: 250,
            pane: "markerPane",
            shadowPane: "shadowPane",
            bubblingMouseEvents: false,
            autoPanOnFocus: true,
            draggable: false,
            autoPan: false,
            autoPanPadding: [50, 50],
            autoPanSpeed: 10
          },
          initialize: function(latlng, options) {
            setOptions(this, options);
            this._latlng = toLatLng(latlng);
          },
          onAdd: function(map) {
            this._zoomAnimated = this._zoomAnimated && map.options.markerZoomAnimation;
            if (this._zoomAnimated) {
              map.on("zoomanim", this._animateZoom, this);
            }
            this._initIcon();
            this.update();
          },
          onRemove: function(map) {
            if (this.dragging && this.dragging.enabled()) {
              this.options.draggable = true;
              this.dragging.removeHooks();
            }
            delete this.dragging;
            if (this._zoomAnimated) {
              map.off("zoomanim", this._animateZoom, this);
            }
            this._removeIcon();
            this._removeShadow();
          },
          getEvents: function() {
            return {
              zoom: this.update,
              viewreset: this.update
            };
          },
          getLatLng: function() {
            return this._latlng;
          },
          setLatLng: function(latlng) {
            var oldLatLng = this._latlng;
            this._latlng = toLatLng(latlng);
            this.update();
            return this.fire("move", { oldLatLng, latlng: this._latlng });
          },
          setZIndexOffset: function(offset) {
            this.options.zIndexOffset = offset;
            return this.update();
          },
          getIcon: function() {
            return this.options.icon;
          },
          setIcon: function(icon2) {
            this.options.icon = icon2;
            if (this._map) {
              this._initIcon();
              this.update();
            }
            if (this._popup) {
              this.bindPopup(this._popup, this._popup.options);
            }
            return this;
          },
          getElement: function() {
            return this._icon;
          },
          update: function() {
            if (this._icon && this._map) {
              var pos = this._map.latLngToLayerPoint(this._latlng).round();
              this._setPos(pos);
            }
            return this;
          },
          _initIcon: function() {
            var options = this.options, classToAdd = "leaflet-zoom-" + (this._zoomAnimated ? "animated" : "hide");
            var icon2 = options.icon.createIcon(this._icon), addIcon = false;
            if (icon2 !== this._icon) {
              if (this._icon) {
                this._removeIcon();
              }
              addIcon = true;
              if (options.title) {
                icon2.title = options.title;
              }
              if (icon2.tagName === "IMG") {
                icon2.alt = options.alt || "";
              }
            }
            addClass(icon2, classToAdd);
            if (options.keyboard) {
              icon2.tabIndex = "0";
              icon2.setAttribute("role", "button");
            }
            this._icon = icon2;
            if (options.riseOnHover) {
              this.on({
                mouseover: this._bringToFront,
                mouseout: this._resetZIndex
              });
            }
            if (this.options.autoPanOnFocus) {
              on(icon2, "focus", this._panOnFocus, this);
            }
            var newShadow = options.icon.createShadow(this._shadow), addShadow = false;
            if (newShadow !== this._shadow) {
              this._removeShadow();
              addShadow = true;
            }
            if (newShadow) {
              addClass(newShadow, classToAdd);
              newShadow.alt = "";
            }
            this._shadow = newShadow;
            if (options.opacity < 1) {
              this._updateOpacity();
            }
            if (addIcon) {
              this.getPane().appendChild(this._icon);
            }
            this._initInteraction();
            if (newShadow && addShadow) {
              this.getPane(options.shadowPane).appendChild(this._shadow);
            }
          },
          _removeIcon: function() {
            if (this.options.riseOnHover) {
              this.off({
                mouseover: this._bringToFront,
                mouseout: this._resetZIndex
              });
            }
            if (this.options.autoPanOnFocus) {
              off(this._icon, "focus", this._panOnFocus, this);
            }
            remove(this._icon);
            this.removeInteractiveTarget(this._icon);
            this._icon = null;
          },
          _removeShadow: function() {
            if (this._shadow) {
              remove(this._shadow);
            }
            this._shadow = null;
          },
          _setPos: function(pos) {
            if (this._icon) {
              setPosition(this._icon, pos);
            }
            if (this._shadow) {
              setPosition(this._shadow, pos);
            }
            this._zIndex = pos.y + this.options.zIndexOffset;
            this._resetZIndex();
          },
          _updateZIndex: function(offset) {
            if (this._icon) {
              this._icon.style.zIndex = this._zIndex + offset;
            }
          },
          _animateZoom: function(opt) {
            var pos = this._map._latLngToNewLayerPoint(this._latlng, opt.zoom, opt.center).round();
            this._setPos(pos);
          },
          _initInteraction: function() {
            if (!this.options.interactive) {
              return;
            }
            addClass(this._icon, "leaflet-interactive");
            this.addInteractiveTarget(this._icon);
            if (MarkerDrag) {
              var draggable = this.options.draggable;
              if (this.dragging) {
                draggable = this.dragging.enabled();
                this.dragging.disable();
              }
              this.dragging = new MarkerDrag(this);
              if (draggable) {
                this.dragging.enable();
              }
            }
          },
          setOpacity: function(opacity) {
            this.options.opacity = opacity;
            if (this._map) {
              this._updateOpacity();
            }
            return this;
          },
          _updateOpacity: function() {
            var opacity = this.options.opacity;
            if (this._icon) {
              setOpacity(this._icon, opacity);
            }
            if (this._shadow) {
              setOpacity(this._shadow, opacity);
            }
          },
          _bringToFront: function() {
            this._updateZIndex(this.options.riseOffset);
          },
          _resetZIndex: function() {
            this._updateZIndex(0);
          },
          _panOnFocus: function() {
            var map = this._map;
            if (!map) {
              return;
            }
            var iconOpts = this.options.icon.options;
            var size = iconOpts.iconSize ? toPoint(iconOpts.iconSize) : toPoint(0, 0);
            var anchor = iconOpts.iconAnchor ? toPoint(iconOpts.iconAnchor) : toPoint(0, 0);
            map.panInside(this._latlng, {
              paddingTopLeft: anchor,
              paddingBottomRight: size.subtract(anchor)
            });
          },
          _getPopupAnchor: function() {
            return this.options.icon.options.popupAnchor;
          },
          _getTooltipAnchor: function() {
            return this.options.icon.options.tooltipAnchor;
          }
        });
        function marker(latlng, options) {
          return new Marker(latlng, options);
        }
        var Path = Layer.extend({
          options: {
            stroke: true,
            color: "#3388ff",
            weight: 3,
            opacity: 1,
            lineCap: "round",
            lineJoin: "round",
            dashArray: null,
            dashOffset: null,
            fill: false,
            fillColor: null,
            fillOpacity: 0.2,
            fillRule: "evenodd",
            interactive: true,
            bubblingMouseEvents: true
          },
          beforeAdd: function(map) {
            this._renderer = map.getRenderer(this);
          },
          onAdd: function() {
            this._renderer._initPath(this);
            this._reset();
            this._renderer._addPath(this);
          },
          onRemove: function() {
            this._renderer._removePath(this);
          },
          redraw: function() {
            if (this._map) {
              this._renderer._updatePath(this);
            }
            return this;
          },
          setStyle: function(style2) {
            setOptions(this, style2);
            if (this._renderer) {
              this._renderer._updateStyle(this);
              if (this.options.stroke && style2 && Object.prototype.hasOwnProperty.call(style2, "weight")) {
                this._updateBounds();
              }
            }
            return this;
          },
          bringToFront: function() {
            if (this._renderer) {
              this._renderer._bringToFront(this);
            }
            return this;
          },
          bringToBack: function() {
            if (this._renderer) {
              this._renderer._bringToBack(this);
            }
            return this;
          },
          getElement: function() {
            return this._path;
          },
          _reset: function() {
            this._project();
            this._update();
          },
          _clickTolerance: function() {
            return (this.options.stroke ? this.options.weight / 2 : 0) + (this._renderer.options.tolerance || 0);
          }
        });
        var CircleMarker = Path.extend({
          options: {
            fill: true,
            radius: 10
          },
          initialize: function(latlng, options) {
            setOptions(this, options);
            this._latlng = toLatLng(latlng);
            this._radius = this.options.radius;
          },
          setLatLng: function(latlng) {
            var oldLatLng = this._latlng;
            this._latlng = toLatLng(latlng);
            this.redraw();
            return this.fire("move", { oldLatLng, latlng: this._latlng });
          },
          getLatLng: function() {
            return this._latlng;
          },
          setRadius: function(radius) {
            this.options.radius = this._radius = radius;
            return this.redraw();
          },
          getRadius: function() {
            return this._radius;
          },
          setStyle: function(options) {
            var radius = options && options.radius || this._radius;
            Path.prototype.setStyle.call(this, options);
            this.setRadius(radius);
            return this;
          },
          _project: function() {
            this._point = this._map.latLngToLayerPoint(this._latlng);
            this._updateBounds();
          },
          _updateBounds: function() {
            var r = this._radius, r2 = this._radiusY || r, w = this._clickTolerance(), p = [r + w, r2 + w];
            this._pxBounds = new Bounds(this._point.subtract(p), this._point.add(p));
          },
          _update: function() {
            if (this._map) {
              this._updatePath();
            }
          },
          _updatePath: function() {
            this._renderer._updateCircle(this);
          },
          _empty: function() {
            return this._radius && !this._renderer._bounds.intersects(this._pxBounds);
          },
          _containsPoint: function(p) {
            return p.distanceTo(this._point) <= this._radius + this._clickTolerance();
          }
        });
        function circleMarker(latlng, options) {
          return new CircleMarker(latlng, options);
        }
        var Circle = CircleMarker.extend({
          initialize: function(latlng, options, legacyOptions) {
            if (typeof options === "number") {
              options = extend({}, legacyOptions, { radius: options });
            }
            setOptions(this, options);
            this._latlng = toLatLng(latlng);
            if (isNaN(this.options.radius)) {
              throw new Error("Circle radius cannot be NaN");
            }
            this._mRadius = this.options.radius;
          },
          setRadius: function(radius) {
            this._mRadius = radius;
            return this.redraw();
          },
          getRadius: function() {
            return this._mRadius;
          },
          getBounds: function() {
            var half = [this._radius, this._radiusY || this._radius];
            return new LatLngBounds(
              this._map.layerPointToLatLng(this._point.subtract(half)),
              this._map.layerPointToLatLng(this._point.add(half))
            );
          },
          setStyle: Path.prototype.setStyle,
          _project: function() {
            var lng = this._latlng.lng, lat = this._latlng.lat, map = this._map, crs = map.options.crs;
            if (crs.distance === Earth.distance) {
              var d = Math.PI / 180, latR = this._mRadius / Earth.R / d, top = map.project([lat + latR, lng]), bottom = map.project([lat - latR, lng]), p = top.add(bottom).divideBy(2), lat2 = map.unproject(p).lat, lngR = Math.acos((Math.cos(latR * d) - Math.sin(lat * d) * Math.sin(lat2 * d)) / (Math.cos(lat * d) * Math.cos(lat2 * d))) / d;
              if (isNaN(lngR) || lngR === 0) {
                lngR = latR / Math.cos(Math.PI / 180 * lat);
              }
              this._point = p.subtract(map.getPixelOrigin());
              this._radius = isNaN(lngR) ? 0 : p.x - map.project([lat2, lng - lngR]).x;
              this._radiusY = p.y - top.y;
            } else {
              var latlng2 = crs.unproject(crs.project(this._latlng).subtract([this._mRadius, 0]));
              this._point = map.latLngToLayerPoint(this._latlng);
              this._radius = this._point.x - map.latLngToLayerPoint(latlng2).x;
            }
            this._updateBounds();
          }
        });
        function circle(latlng, options, legacyOptions) {
          return new Circle(latlng, options, legacyOptions);
        }
        var Polyline = Path.extend({
          options: {
            smoothFactor: 1,
            noClip: false
          },
          initialize: function(latlngs, options) {
            setOptions(this, options);
            this._setLatLngs(latlngs);
          },
          getLatLngs: function() {
            return this._latlngs;
          },
          setLatLngs: function(latlngs) {
            this._setLatLngs(latlngs);
            return this.redraw();
          },
          isEmpty: function() {
            return !this._latlngs.length;
          },
          closestLayerPoint: function(p) {
            var minDistance = Infinity, minPoint = null, closest = _sqClosestPointOnSegment, p1, p2;
            for (var j = 0, jLen = this._parts.length; j < jLen; j++) {
              var points = this._parts[j];
              for (var i = 1, len = points.length; i < len; i++) {
                p1 = points[i - 1];
                p2 = points[i];
                var sqDist = closest(p, p1, p2, true);
                if (sqDist < minDistance) {
                  minDistance = sqDist;
                  minPoint = closest(p, p1, p2);
                }
              }
            }
            if (minPoint) {
              minPoint.distance = Math.sqrt(minDistance);
            }
            return minPoint;
          },
          getCenter: function() {
            if (!this._map) {
              throw new Error("Must add layer to map before using getCenter()");
            }
            var i, halfDist, segDist, dist, p1, p2, ratio, points = this._rings[0], len = points.length;
            if (!len) {
              return null;
            }
            for (i = 0, halfDist = 0; i < len - 1; i++) {
              halfDist += points[i].distanceTo(points[i + 1]) / 2;
            }
            if (halfDist === 0) {
              return this._map.layerPointToLatLng(points[0]);
            }
            for (i = 0, dist = 0; i < len - 1; i++) {
              p1 = points[i];
              p2 = points[i + 1];
              segDist = p1.distanceTo(p2);
              dist += segDist;
              if (dist > halfDist) {
                ratio = (dist - halfDist) / segDist;
                return this._map.layerPointToLatLng([
                  p2.x - ratio * (p2.x - p1.x),
                  p2.y - ratio * (p2.y - p1.y)
                ]);
              }
            }
          },
          getBounds: function() {
            return this._bounds;
          },
          addLatLng: function(latlng, latlngs) {
            latlngs = latlngs || this._defaultShape();
            latlng = toLatLng(latlng);
            latlngs.push(latlng);
            this._bounds.extend(latlng);
            return this.redraw();
          },
          _setLatLngs: function(latlngs) {
            this._bounds = new LatLngBounds();
            this._latlngs = this._convertLatLngs(latlngs);
          },
          _defaultShape: function() {
            return isFlat(this._latlngs) ? this._latlngs : this._latlngs[0];
          },
          _convertLatLngs: function(latlngs) {
            var result = [], flat = isFlat(latlngs);
            for (var i = 0, len = latlngs.length; i < len; i++) {
              if (flat) {
                result[i] = toLatLng(latlngs[i]);
                this._bounds.extend(result[i]);
              } else {
                result[i] = this._convertLatLngs(latlngs[i]);
              }
            }
            return result;
          },
          _project: function() {
            var pxBounds = new Bounds();
            this._rings = [];
            this._projectLatlngs(this._latlngs, this._rings, pxBounds);
            if (this._bounds.isValid() && pxBounds.isValid()) {
              this._rawPxBounds = pxBounds;
              this._updateBounds();
            }
          },
          _updateBounds: function() {
            var w = this._clickTolerance(), p = new Point(w, w);
            if (!this._rawPxBounds) {
              return;
            }
            this._pxBounds = new Bounds([
              this._rawPxBounds.min.subtract(p),
              this._rawPxBounds.max.add(p)
            ]);
          },
          _projectLatlngs: function(latlngs, result, projectedBounds) {
            var flat = latlngs[0] instanceof LatLng, len = latlngs.length, i, ring;
            if (flat) {
              ring = [];
              for (i = 0; i < len; i++) {
                ring[i] = this._map.latLngToLayerPoint(latlngs[i]);
                projectedBounds.extend(ring[i]);
              }
              result.push(ring);
            } else {
              for (i = 0; i < len; i++) {
                this._projectLatlngs(latlngs[i], result, projectedBounds);
              }
            }
          },
          _clipPoints: function() {
            var bounds = this._renderer._bounds;
            this._parts = [];
            if (!this._pxBounds || !this._pxBounds.intersects(bounds)) {
              return;
            }
            if (this.options.noClip) {
              this._parts = this._rings;
              return;
            }
            var parts = this._parts, i, j, k, len, len2, segment, points;
            for (i = 0, k = 0, len = this._rings.length; i < len; i++) {
              points = this._rings[i];
              for (j = 0, len2 = points.length; j < len2 - 1; j++) {
                segment = clipSegment(points[j], points[j + 1], bounds, j, true);
                if (!segment) {
                  continue;
                }
                parts[k] = parts[k] || [];
                parts[k].push(segment[0]);
                if (segment[1] !== points[j + 1] || j === len2 - 2) {
                  parts[k].push(segment[1]);
                  k++;
                }
              }
            }
          },
          _simplifyPoints: function() {
            var parts = this._parts, tolerance = this.options.smoothFactor;
            for (var i = 0, len = parts.length; i < len; i++) {
              parts[i] = simplify(parts[i], tolerance);
            }
          },
          _update: function() {
            if (!this._map) {
              return;
            }
            this._clipPoints();
            this._simplifyPoints();
            this._updatePath();
          },
          _updatePath: function() {
            this._renderer._updatePoly(this);
          },
          _containsPoint: function(p, closed) {
            var i, j, k, len, len2, part, w = this._clickTolerance();
            if (!this._pxBounds || !this._pxBounds.contains(p)) {
              return false;
            }
            for (i = 0, len = this._parts.length; i < len; i++) {
              part = this._parts[i];
              for (j = 0, len2 = part.length, k = len2 - 1; j < len2; k = j++) {
                if (!closed && j === 0) {
                  continue;
                }
                if (pointToSegmentDistance(p, part[k], part[j]) <= w) {
                  return true;
                }
              }
            }
            return false;
          }
        });
        function polyline(latlngs, options) {
          return new Polyline(latlngs, options);
        }
        Polyline._flat = _flat;
        var Polygon = Polyline.extend({
          options: {
            fill: true
          },
          isEmpty: function() {
            return !this._latlngs.length || !this._latlngs[0].length;
          },
          getCenter: function() {
            if (!this._map) {
              throw new Error("Must add layer to map before using getCenter()");
            }
            var i, j, p1, p2, f, area, x, y, center, points = this._rings[0], len = points.length;
            if (!len) {
              return null;
            }
            area = x = y = 0;
            for (i = 0, j = len - 1; i < len; j = i++) {
              p1 = points[i];
              p2 = points[j];
              f = p1.y * p2.x - p2.y * p1.x;
              x += (p1.x + p2.x) * f;
              y += (p1.y + p2.y) * f;
              area += f * 3;
            }
            if (area === 0) {
              center = points[0];
            } else {
              center = [x / area, y / area];
            }
            return this._map.layerPointToLatLng(center);
          },
          _convertLatLngs: function(latlngs) {
            var result = Polyline.prototype._convertLatLngs.call(this, latlngs), len = result.length;
            if (len >= 2 && result[0] instanceof LatLng && result[0].equals(result[len - 1])) {
              result.pop();
            }
            return result;
          },
          _setLatLngs: function(latlngs) {
            Polyline.prototype._setLatLngs.call(this, latlngs);
            if (isFlat(this._latlngs)) {
              this._latlngs = [this._latlngs];
            }
          },
          _defaultShape: function() {
            return isFlat(this._latlngs[0]) ? this._latlngs[0] : this._latlngs[0][0];
          },
          _clipPoints: function() {
            var bounds = this._renderer._bounds, w = this.options.weight, p = new Point(w, w);
            bounds = new Bounds(bounds.min.subtract(p), bounds.max.add(p));
            this._parts = [];
            if (!this._pxBounds || !this._pxBounds.intersects(bounds)) {
              return;
            }
            if (this.options.noClip) {
              this._parts = this._rings;
              return;
            }
            for (var i = 0, len = this._rings.length, clipped; i < len; i++) {
              clipped = clipPolygon(this._rings[i], bounds, true);
              if (clipped.length) {
                this._parts.push(clipped);
              }
            }
          },
          _updatePath: function() {
            this._renderer._updatePoly(this, true);
          },
          _containsPoint: function(p) {
            var inside = false, part, p1, p2, i, j, k, len, len2;
            if (!this._pxBounds || !this._pxBounds.contains(p)) {
              return false;
            }
            for (i = 0, len = this._parts.length; i < len; i++) {
              part = this._parts[i];
              for (j = 0, len2 = part.length, k = len2 - 1; j < len2; k = j++) {
                p1 = part[j];
                p2 = part[k];
                if (p1.y > p.y !== p2.y > p.y && p.x < (p2.x - p1.x) * (p.y - p1.y) / (p2.y - p1.y) + p1.x) {
                  inside = !inside;
                }
              }
            }
            return inside || Polyline.prototype._containsPoint.call(this, p, true);
          }
        });
        function polygon(latlngs, options) {
          return new Polygon(latlngs, options);
        }
        var GeoJSON = FeatureGroup.extend({
          initialize: function(geojson, options) {
            setOptions(this, options);
            this._layers = {};
            if (geojson) {
              this.addData(geojson);
            }
          },
          addData: function(geojson) {
            var features = isArray(geojson) ? geojson : geojson.features, i, len, feature;
            if (features) {
              for (i = 0, len = features.length; i < len; i++) {
                feature = features[i];
                if (feature.geometries || feature.geometry || feature.features || feature.coordinates) {
                  this.addData(feature);
                }
              }
              return this;
            }
            var options = this.options;
            if (options.filter && !options.filter(geojson)) {
              return this;
            }
            var layer = geometryToLayer(geojson, options);
            if (!layer) {
              return this;
            }
            layer.feature = asFeature(geojson);
            layer.defaultOptions = layer.options;
            this.resetStyle(layer);
            if (options.onEachFeature) {
              options.onEachFeature(geojson, layer);
            }
            return this.addLayer(layer);
          },
          resetStyle: function(layer) {
            if (layer === void 0) {
              return this.eachLayer(this.resetStyle, this);
            }
            layer.options = extend({}, layer.defaultOptions);
            this._setLayerStyle(layer, this.options.style);
            return this;
          },
          setStyle: function(style2) {
            return this.eachLayer(function(layer) {
              this._setLayerStyle(layer, style2);
            }, this);
          },
          _setLayerStyle: function(layer, style2) {
            if (layer.setStyle) {
              if (typeof style2 === "function") {
                style2 = style2(layer.feature);
              }
              layer.setStyle(style2);
            }
          }
        });
        function geometryToLayer(geojson, options) {
          var geometry = geojson.type === "Feature" ? geojson.geometry : geojson, coords = geometry ? geometry.coordinates : null, layers2 = [], pointToLayer = options && options.pointToLayer, _coordsToLatLng = options && options.coordsToLatLng || coordsToLatLng, latlng, latlngs, i, len;
          if (!coords && !geometry) {
            return null;
          }
          switch (geometry.type) {
            case "Point":
              latlng = _coordsToLatLng(coords);
              return _pointToLayer(pointToLayer, geojson, latlng, options);
            case "MultiPoint":
              for (i = 0, len = coords.length; i < len; i++) {
                latlng = _coordsToLatLng(coords[i]);
                layers2.push(_pointToLayer(pointToLayer, geojson, latlng, options));
              }
              return new FeatureGroup(layers2);
            case "LineString":
            case "MultiLineString":
              latlngs = coordsToLatLngs(coords, geometry.type === "LineString" ? 0 : 1, _coordsToLatLng);
              return new Polyline(latlngs, options);
            case "Polygon":
            case "MultiPolygon":
              latlngs = coordsToLatLngs(coords, geometry.type === "Polygon" ? 1 : 2, _coordsToLatLng);
              return new Polygon(latlngs, options);
            case "GeometryCollection":
              for (i = 0, len = geometry.geometries.length; i < len; i++) {
                var layer = geometryToLayer({
                  geometry: geometry.geometries[i],
                  type: "Feature",
                  properties: geojson.properties
                }, options);
                if (layer) {
                  layers2.push(layer);
                }
              }
              return new FeatureGroup(layers2);
            default:
              throw new Error("Invalid GeoJSON object.");
          }
        }
        function _pointToLayer(pointToLayerFn, geojson, latlng, options) {
          return pointToLayerFn ? pointToLayerFn(geojson, latlng) : new Marker(latlng, options && options.markersInheritOptions && options);
        }
        function coordsToLatLng(coords) {
          return new LatLng(coords[1], coords[0], coords[2]);
        }
        function coordsToLatLngs(coords, levelsDeep, _coordsToLatLng) {
          var latlngs = [];
          for (var i = 0, len = coords.length, latlng; i < len; i++) {
            latlng = levelsDeep ? coordsToLatLngs(coords[i], levelsDeep - 1, _coordsToLatLng) : (_coordsToLatLng || coordsToLatLng)(coords[i]);
            latlngs.push(latlng);
          }
          return latlngs;
        }
        function latLngToCoords(latlng, precision) {
          latlng = toLatLng(latlng);
          return latlng.alt !== void 0 ? [formatNum(latlng.lng, precision), formatNum(latlng.lat, precision), formatNum(latlng.alt, precision)] : [formatNum(latlng.lng, precision), formatNum(latlng.lat, precision)];
        }
        function latLngsToCoords(latlngs, levelsDeep, closed, precision) {
          var coords = [];
          for (var i = 0, len = latlngs.length; i < len; i++) {
            coords.push(levelsDeep ? latLngsToCoords(latlngs[i], levelsDeep - 1, closed, precision) : latLngToCoords(latlngs[i], precision));
          }
          if (!levelsDeep && closed) {
            coords.push(coords[0]);
          }
          return coords;
        }
        function getFeature(layer, newGeometry) {
          return layer.feature ? extend({}, layer.feature, { geometry: newGeometry }) : asFeature(newGeometry);
        }
        function asFeature(geojson) {
          if (geojson.type === "Feature" || geojson.type === "FeatureCollection") {
            return geojson;
          }
          return {
            type: "Feature",
            properties: {},
            geometry: geojson
          };
        }
        var PointToGeoJSON = {
          toGeoJSON: function(precision) {
            return getFeature(this, {
              type: "Point",
              coordinates: latLngToCoords(this.getLatLng(), precision)
            });
          }
        };
        Marker.include(PointToGeoJSON);
        Circle.include(PointToGeoJSON);
        CircleMarker.include(PointToGeoJSON);
        Polyline.include({
          toGeoJSON: function(precision) {
            var multi = !isFlat(this._latlngs);
            var coords = latLngsToCoords(this._latlngs, multi ? 1 : 0, false, precision);
            return getFeature(this, {
              type: (multi ? "Multi" : "") + "LineString",
              coordinates: coords
            });
          }
        });
        Polygon.include({
          toGeoJSON: function(precision) {
            var holes = !isFlat(this._latlngs), multi = holes && !isFlat(this._latlngs[0]);
            var coords = latLngsToCoords(this._latlngs, multi ? 2 : holes ? 1 : 0, true, precision);
            if (!holes) {
              coords = [coords];
            }
            return getFeature(this, {
              type: (multi ? "Multi" : "") + "Polygon",
              coordinates: coords
            });
          }
        });
        LayerGroup.include({
          toMultiPoint: function(precision) {
            var coords = [];
            this.eachLayer(function(layer) {
              coords.push(layer.toGeoJSON(precision).geometry.coordinates);
            });
            return getFeature(this, {
              type: "MultiPoint",
              coordinates: coords
            });
          },
          toGeoJSON: function(precision) {
            var type = this.feature && this.feature.geometry && this.feature.geometry.type;
            if (type === "MultiPoint") {
              return this.toMultiPoint(precision);
            }
            var isGeometryCollection = type === "GeometryCollection", jsons = [];
            this.eachLayer(function(layer) {
              if (layer.toGeoJSON) {
                var json = layer.toGeoJSON(precision);
                if (isGeometryCollection) {
                  jsons.push(json.geometry);
                } else {
                  var feature = asFeature(json);
                  if (feature.type === "FeatureCollection") {
                    jsons.push.apply(jsons, feature.features);
                  } else {
                    jsons.push(feature);
                  }
                }
              }
            });
            if (isGeometryCollection) {
              return getFeature(this, {
                geometries: jsons,
                type: "GeometryCollection"
              });
            }
            return {
              type: "FeatureCollection",
              features: jsons
            };
          }
        });
        function geoJSON(geojson, options) {
          return new GeoJSON(geojson, options);
        }
        var geoJson = geoJSON;
        var ImageOverlay = Layer.extend({
          options: {
            opacity: 1,
            alt: "",
            interactive: false,
            crossOrigin: false,
            errorOverlayUrl: "",
            zIndex: 1,
            className: ""
          },
          initialize: function(url, bounds, options) {
            this._url = url;
            this._bounds = toLatLngBounds(bounds);
            setOptions(this, options);
          },
          onAdd: function() {
            if (!this._image) {
              this._initImage();
              if (this.options.opacity < 1) {
                this._updateOpacity();
              }
            }
            if (this.options.interactive) {
              addClass(this._image, "leaflet-interactive");
              this.addInteractiveTarget(this._image);
            }
            this.getPane().appendChild(this._image);
            this._reset();
          },
          onRemove: function() {
            remove(this._image);
            if (this.options.interactive) {
              this.removeInteractiveTarget(this._image);
            }
          },
          setOpacity: function(opacity) {
            this.options.opacity = opacity;
            if (this._image) {
              this._updateOpacity();
            }
            return this;
          },
          setStyle: function(styleOpts) {
            if (styleOpts.opacity) {
              this.setOpacity(styleOpts.opacity);
            }
            return this;
          },
          bringToFront: function() {
            if (this._map) {
              toFront(this._image);
            }
            return this;
          },
          bringToBack: function() {
            if (this._map) {
              toBack(this._image);
            }
            return this;
          },
          setUrl: function(url) {
            this._url = url;
            if (this._image) {
              this._image.src = url;
            }
            return this;
          },
          setBounds: function(bounds) {
            this._bounds = toLatLngBounds(bounds);
            if (this._map) {
              this._reset();
            }
            return this;
          },
          getEvents: function() {
            var events = {
              zoom: this._reset,
              viewreset: this._reset
            };
            if (this._zoomAnimated) {
              events.zoomanim = this._animateZoom;
            }
            return events;
          },
          setZIndex: function(value) {
            this.options.zIndex = value;
            this._updateZIndex();
            return this;
          },
          getBounds: function() {
            return this._bounds;
          },
          getElement: function() {
            return this._image;
          },
          _initImage: function() {
            var wasElementSupplied = this._url.tagName === "IMG";
            var img = this._image = wasElementSupplied ? this._url : create$1("img");
            addClass(img, "leaflet-image-layer");
            if (this._zoomAnimated) {
              addClass(img, "leaflet-zoom-animated");
            }
            if (this.options.className) {
              addClass(img, this.options.className);
            }
            img.onselectstart = falseFn;
            img.onmousemove = falseFn;
            img.onload = bind(this.fire, this, "load");
            img.onerror = bind(this._overlayOnError, this, "error");
            if (this.options.crossOrigin || this.options.crossOrigin === "") {
              img.crossOrigin = this.options.crossOrigin === true ? "" : this.options.crossOrigin;
            }
            if (this.options.zIndex) {
              this._updateZIndex();
            }
            if (wasElementSupplied) {
              this._url = img.src;
              return;
            }
            img.src = this._url;
            img.alt = this.options.alt;
          },
          _animateZoom: function(e) {
            var scale2 = this._map.getZoomScale(e.zoom), offset = this._map._latLngBoundsToNewLayerBounds(this._bounds, e.zoom, e.center).min;
            setTransform(this._image, offset, scale2);
          },
          _reset: function() {
            var image = this._image, bounds = new Bounds(
              this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
              this._map.latLngToLayerPoint(this._bounds.getSouthEast())
            ), size = bounds.getSize();
            setPosition(image, bounds.min);
            image.style.width = size.x + "px";
            image.style.height = size.y + "px";
          },
          _updateOpacity: function() {
            setOpacity(this._image, this.options.opacity);
          },
          _updateZIndex: function() {
            if (this._image && this.options.zIndex !== void 0 && this.options.zIndex !== null) {
              this._image.style.zIndex = this.options.zIndex;
            }
          },
          _overlayOnError: function() {
            this.fire("error");
            var errorUrl = this.options.errorOverlayUrl;
            if (errorUrl && this._url !== errorUrl) {
              this._url = errorUrl;
              this._image.src = errorUrl;
            }
          },
          getCenter: function() {
            return this._bounds.getCenter();
          }
        });
        var imageOverlay = function(url, bounds, options) {
          return new ImageOverlay(url, bounds, options);
        };
        var VideoOverlay = ImageOverlay.extend({
          options: {
            autoplay: true,
            loop: true,
            keepAspectRatio: true,
            muted: false,
            playsInline: true
          },
          _initImage: function() {
            var wasElementSupplied = this._url.tagName === "VIDEO";
            var vid = this._image = wasElementSupplied ? this._url : create$1("video");
            addClass(vid, "leaflet-image-layer");
            if (this._zoomAnimated) {
              addClass(vid, "leaflet-zoom-animated");
            }
            if (this.options.className) {
              addClass(vid, this.options.className);
            }
            vid.onselectstart = falseFn;
            vid.onmousemove = falseFn;
            vid.onloadeddata = bind(this.fire, this, "load");
            if (wasElementSupplied) {
              var sourceElements = vid.getElementsByTagName("source");
              var sources = [];
              for (var j = 0; j < sourceElements.length; j++) {
                sources.push(sourceElements[j].src);
              }
              this._url = sourceElements.length > 0 ? sources : [vid.src];
              return;
            }
            if (!isArray(this._url)) {
              this._url = [this._url];
            }
            if (!this.options.keepAspectRatio && Object.prototype.hasOwnProperty.call(vid.style, "objectFit")) {
              vid.style["objectFit"] = "fill";
            }
            vid.autoplay = !!this.options.autoplay;
            vid.loop = !!this.options.loop;
            vid.muted = !!this.options.muted;
            vid.playsInline = !!this.options.playsInline;
            for (var i = 0; i < this._url.length; i++) {
              var source = create$1("source");
              source.src = this._url[i];
              vid.appendChild(source);
            }
          }
        });
        function videoOverlay(video, bounds, options) {
          return new VideoOverlay(video, bounds, options);
        }
        var SVGOverlay = ImageOverlay.extend({
          _initImage: function() {
            var el = this._image = this._url;
            addClass(el, "leaflet-image-layer");
            if (this._zoomAnimated) {
              addClass(el, "leaflet-zoom-animated");
            }
            if (this.options.className) {
              addClass(el, this.options.className);
            }
            el.onselectstart = falseFn;
            el.onmousemove = falseFn;
          }
        });
        function svgOverlay(el, bounds, options) {
          return new SVGOverlay(el, bounds, options);
        }
        var DivOverlay = Layer.extend({
          options: {
            interactive: false,
            offset: [0, 0],
            className: "",
            pane: void 0
          },
          initialize: function(options, source) {
            setOptions(this, options);
            this._source = source;
          },
          openOn: function(map) {
            map = arguments.length ? map : this._source._map;
            if (!map.hasLayer(this)) {
              map.addLayer(this);
            }
            return this;
          },
          close: function() {
            if (this._map) {
              this._map.removeLayer(this);
            }
            return this;
          },
          toggle: function(layer) {
            if (this._map) {
              this.close();
            } else {
              if (arguments.length) {
                this._source = layer;
              } else {
                layer = this._source;
              }
              this._prepareOpen();
              this.openOn(layer._map);
            }
            return this;
          },
          onAdd: function(map) {
            this._zoomAnimated = map._zoomAnimated;
            if (!this._container) {
              this._initLayout();
            }
            if (map._fadeAnimated) {
              setOpacity(this._container, 0);
            }
            clearTimeout(this._removeTimeout);
            this.getPane().appendChild(this._container);
            this.update();
            if (map._fadeAnimated) {
              setOpacity(this._container, 1);
            }
            this.bringToFront();
            if (this.options.interactive) {
              addClass(this._container, "leaflet-interactive");
              this.addInteractiveTarget(this._container);
            }
          },
          onRemove: function(map) {
            if (map._fadeAnimated) {
              setOpacity(this._container, 0);
              this._removeTimeout = setTimeout(bind(remove, void 0, this._container), 200);
            } else {
              remove(this._container);
            }
            if (this.options.interactive) {
              removeClass(this._container, "leaflet-interactive");
              this.removeInteractiveTarget(this._container);
            }
          },
          getLatLng: function() {
            return this._latlng;
          },
          setLatLng: function(latlng) {
            this._latlng = toLatLng(latlng);
            if (this._map) {
              this._updatePosition();
              this._adjustPan();
            }
            return this;
          },
          getContent: function() {
            return this._content;
          },
          setContent: function(content) {
            this._content = content;
            this.update();
            return this;
          },
          getElement: function() {
            return this._container;
          },
          update: function() {
            if (!this._map) {
              return;
            }
            this._container.style.visibility = "hidden";
            this._updateContent();
            this._updateLayout();
            this._updatePosition();
            this._container.style.visibility = "";
            this._adjustPan();
          },
          getEvents: function() {
            var events = {
              zoom: this._updatePosition,
              viewreset: this._updatePosition
            };
            if (this._zoomAnimated) {
              events.zoomanim = this._animateZoom;
            }
            return events;
          },
          isOpen: function() {
            return !!this._map && this._map.hasLayer(this);
          },
          bringToFront: function() {
            if (this._map) {
              toFront(this._container);
            }
            return this;
          },
          bringToBack: function() {
            if (this._map) {
              toBack(this._container);
            }
            return this;
          },
          _prepareOpen: function(latlng) {
            var source = this._source;
            if (!source._map) {
              return false;
            }
            if (source instanceof FeatureGroup) {
              source = null;
              var layers2 = this._source._layers;
              for (var id in layers2) {
                if (layers2[id]._map) {
                  source = layers2[id];
                  break;
                }
              }
              if (!source) {
                return false;
              }
              this._source = source;
            }
            if (!latlng) {
              if (source.getCenter) {
                latlng = source.getCenter();
              } else if (source.getLatLng) {
                latlng = source.getLatLng();
              } else if (source.getBounds) {
                latlng = source.getBounds().getCenter();
              } else {
                throw new Error("Unable to get source layer LatLng.");
              }
            }
            this.setLatLng(latlng);
            if (this._map) {
              this.update();
            }
            return true;
          },
          _updateContent: function() {
            if (!this._content) {
              return;
            }
            var node = this._contentNode;
            var content = typeof this._content === "function" ? this._content(this._source || this) : this._content;
            if (typeof content === "string") {
              node.innerHTML = content;
            } else {
              while (node.hasChildNodes()) {
                node.removeChild(node.firstChild);
              }
              node.appendChild(content);
            }
            this.fire("contentupdate");
          },
          _updatePosition: function() {
            if (!this._map) {
              return;
            }
            var pos = this._map.latLngToLayerPoint(this._latlng), offset = toPoint(this.options.offset), anchor = this._getAnchor();
            if (this._zoomAnimated) {
              setPosition(this._container, pos.add(anchor));
            } else {
              offset = offset.add(pos).add(anchor);
            }
            var bottom = this._containerBottom = -offset.y, left = this._containerLeft = -Math.round(this._containerWidth / 2) + offset.x;
            this._container.style.bottom = bottom + "px";
            this._container.style.left = left + "px";
          },
          _getAnchor: function() {
            return [0, 0];
          }
        });
        Map.include({
          _initOverlay: function(OverlayClass, content, latlng, options) {
            var overlay = content;
            if (!(overlay instanceof OverlayClass)) {
              overlay = new OverlayClass(options).setContent(content);
            }
            if (latlng) {
              overlay.setLatLng(latlng);
            }
            return overlay;
          }
        });
        Layer.include({
          _initOverlay: function(OverlayClass, old, content, options) {
            var overlay = content;
            if (overlay instanceof OverlayClass) {
              setOptions(overlay, options);
              overlay._source = this;
            } else {
              overlay = old && !options ? old : new OverlayClass(options, this);
              overlay.setContent(content);
            }
            return overlay;
          }
        });
        var Popup = DivOverlay.extend({
          options: {
            pane: "popupPane",
            offset: [0, 7],
            maxWidth: 300,
            minWidth: 50,
            maxHeight: null,
            autoPan: true,
            autoPanPaddingTopLeft: null,
            autoPanPaddingBottomRight: null,
            autoPanPadding: [5, 5],
            keepInView: false,
            closeButton: true,
            autoClose: true,
            closeOnEscapeKey: true,
            className: ""
          },
          openOn: function(map) {
            map = arguments.length ? map : this._source._map;
            if (!map.hasLayer(this) && map._popup && map._popup.options.autoClose) {
              map.removeLayer(map._popup);
            }
            map._popup = this;
            return DivOverlay.prototype.openOn.call(this, map);
          },
          onAdd: function(map) {
            DivOverlay.prototype.onAdd.call(this, map);
            map.fire("popupopen", { popup: this });
            if (this._source) {
              this._source.fire("popupopen", { popup: this }, true);
              if (!(this._source instanceof Path)) {
                this._source.on("preclick", stopPropagation);
              }
            }
          },
          onRemove: function(map) {
            DivOverlay.prototype.onRemove.call(this, map);
            map.fire("popupclose", { popup: this });
            if (this._source) {
              this._source.fire("popupclose", { popup: this }, true);
              if (!(this._source instanceof Path)) {
                this._source.off("preclick", stopPropagation);
              }
            }
          },
          getEvents: function() {
            var events = DivOverlay.prototype.getEvents.call(this);
            if (this.options.closeOnClick !== void 0 ? this.options.closeOnClick : this._map.options.closePopupOnClick) {
              events.preclick = this.close;
            }
            if (this.options.keepInView) {
              events.moveend = this._adjustPan;
            }
            return events;
          },
          _initLayout: function() {
            var prefix = "leaflet-popup", container = this._container = create$1(
              "div",
              prefix + " " + (this.options.className || "") + " leaflet-zoom-animated"
            );
            var wrapper = this._wrapper = create$1("div", prefix + "-content-wrapper", container);
            this._contentNode = create$1("div", prefix + "-content", wrapper);
            disableClickPropagation(container);
            disableScrollPropagation(this._contentNode);
            on(container, "contextmenu", stopPropagation);
            this._tipContainer = create$1("div", prefix + "-tip-container", container);
            this._tip = create$1("div", prefix + "-tip", this._tipContainer);
            if (this.options.closeButton) {
              var closeButton = this._closeButton = create$1("a", prefix + "-close-button", container);
              closeButton.setAttribute("role", "button");
              closeButton.setAttribute("aria-label", "Close popup");
              closeButton.href = "#close";
              closeButton.innerHTML = '<span aria-hidden="true">&#215;</span>';
              on(closeButton, "click", this.close, this);
            }
          },
          _updateLayout: function() {
            var container = this._contentNode, style2 = container.style;
            style2.width = "";
            style2.whiteSpace = "nowrap";
            var width = container.offsetWidth;
            width = Math.min(width, this.options.maxWidth);
            width = Math.max(width, this.options.minWidth);
            style2.width = width + 1 + "px";
            style2.whiteSpace = "";
            style2.height = "";
            var height = container.offsetHeight, maxHeight = this.options.maxHeight, scrolledClass = "leaflet-popup-scrolled";
            if (maxHeight && height > maxHeight) {
              style2.height = maxHeight + "px";
              addClass(container, scrolledClass);
            } else {
              removeClass(container, scrolledClass);
            }
            this._containerWidth = this._container.offsetWidth;
          },
          _animateZoom: function(e) {
            var pos = this._map._latLngToNewLayerPoint(this._latlng, e.zoom, e.center), anchor = this._getAnchor();
            setPosition(this._container, pos.add(anchor));
          },
          _adjustPan: function(e) {
            if (!this.options.autoPan) {
              return;
            }
            if (this._map._panAnim) {
              this._map._panAnim.stop();
            }
            var map = this._map, marginBottom = parseInt(getStyle(this._container, "marginBottom"), 10) || 0, containerHeight = this._container.offsetHeight + marginBottom, containerWidth = this._containerWidth, layerPos = new Point(this._containerLeft, -containerHeight - this._containerBottom);
            layerPos._add(getPosition(this._container));
            var containerPos = map.layerPointToContainerPoint(layerPos), padding = toPoint(this.options.autoPanPadding), paddingTL = toPoint(this.options.autoPanPaddingTopLeft || padding), paddingBR = toPoint(this.options.autoPanPaddingBottomRight || padding), size = map.getSize(), dx = 0, dy = 0;
            if (containerPos.x + containerWidth + paddingBR.x > size.x) {
              dx = containerPos.x + containerWidth - size.x + paddingBR.x;
            }
            if (containerPos.x - dx - paddingTL.x < 0) {
              dx = containerPos.x - paddingTL.x;
            }
            if (containerPos.y + containerHeight + paddingBR.y > size.y) {
              dy = containerPos.y + containerHeight - size.y + paddingBR.y;
            }
            if (containerPos.y - dy - paddingTL.y < 0) {
              dy = containerPos.y - paddingTL.y;
            }
            if (dx || dy) {
              map.fire("autopanstart").panBy([dx, dy], { animate: e && e.type === "moveend" });
            }
          },
          _getAnchor: function() {
            return toPoint(this._source && this._source._getPopupAnchor ? this._source._getPopupAnchor() : [0, 0]);
          }
        });
        var popup = function(options, source) {
          return new Popup(options, source);
        };
        Map.mergeOptions({
          closePopupOnClick: true
        });
        Map.include({
          openPopup: function(popup2, latlng, options) {
            this._initOverlay(Popup, popup2, latlng, options).openOn(this);
            return this;
          },
          closePopup: function(popup2) {
            popup2 = arguments.length ? popup2 : this._popup;
            if (popup2) {
              popup2.close();
            }
            return this;
          }
        });
        Layer.include({
          bindPopup: function(content, options) {
            this._popup = this._initOverlay(Popup, this._popup, content, options);
            if (!this._popupHandlersAdded) {
              this.on({
                click: this._openPopup,
                keypress: this._onKeyPress,
                remove: this.closePopup,
                move: this._movePopup
              });
              this._popupHandlersAdded = true;
            }
            return this;
          },
          unbindPopup: function() {
            if (this._popup) {
              this.off({
                click: this._openPopup,
                keypress: this._onKeyPress,
                remove: this.closePopup,
                move: this._movePopup
              });
              this._popupHandlersAdded = false;
              this._popup = null;
            }
            return this;
          },
          openPopup: function(latlng) {
            if (this._popup && this._popup._prepareOpen(latlng)) {
              this._popup.openOn(this._map);
            }
            return this;
          },
          closePopup: function() {
            if (this._popup) {
              this._popup.close();
            }
            return this;
          },
          togglePopup: function() {
            if (this._popup) {
              this._popup.toggle(this);
            }
            return this;
          },
          isPopupOpen: function() {
            return this._popup ? this._popup.isOpen() : false;
          },
          setPopupContent: function(content) {
            if (this._popup) {
              this._popup.setContent(content);
            }
            return this;
          },
          getPopup: function() {
            return this._popup;
          },
          _openPopup: function(e) {
            if (!this._popup || !this._map) {
              return;
            }
            stop(e);
            var target = e.layer || e.target;
            if (this._popup._source === target && !(target instanceof Path)) {
              if (this._map.hasLayer(this._popup)) {
                this.closePopup();
              } else {
                this.openPopup(e.latlng);
              }
              return;
            }
            this._popup._source = target;
            this.openPopup(e.latlng);
          },
          _movePopup: function(e) {
            this._popup.setLatLng(e.latlng);
          },
          _onKeyPress: function(e) {
            if (e.originalEvent.keyCode === 13) {
              this._openPopup(e);
            }
          }
        });
        var Tooltip = DivOverlay.extend({
          options: {
            pane: "tooltipPane",
            offset: [0, 0],
            direction: "auto",
            permanent: false,
            sticky: false,
            opacity: 0.9
          },
          onAdd: function(map) {
            DivOverlay.prototype.onAdd.call(this, map);
            this.setOpacity(this.options.opacity);
            map.fire("tooltipopen", { tooltip: this });
            if (this._source) {
              this.addEventParent(this._source);
              this._source.fire("tooltipopen", { tooltip: this }, true);
            }
          },
          onRemove: function(map) {
            DivOverlay.prototype.onRemove.call(this, map);
            map.fire("tooltipclose", { tooltip: this });
            if (this._source) {
              this.removeEventParent(this._source);
              this._source.fire("tooltipclose", { tooltip: this }, true);
            }
          },
          getEvents: function() {
            var events = DivOverlay.prototype.getEvents.call(this);
            if (!this.options.permanent) {
              events.preclick = this.close;
            }
            return events;
          },
          _initLayout: function() {
            var prefix = "leaflet-tooltip", className = prefix + " " + (this.options.className || "") + " leaflet-zoom-" + (this._zoomAnimated ? "animated" : "hide");
            this._contentNode = this._container = create$1("div", className);
          },
          _updateLayout: function() {
          },
          _adjustPan: function() {
          },
          _setPosition: function(pos) {
            var subX, subY, map = this._map, container = this._container, centerPoint = map.latLngToContainerPoint(map.getCenter()), tooltipPoint = map.layerPointToContainerPoint(pos), direction = this.options.direction, tooltipWidth = container.offsetWidth, tooltipHeight = container.offsetHeight, offset = toPoint(this.options.offset), anchor = this._getAnchor();
            if (direction === "top") {
              subX = tooltipWidth / 2;
              subY = tooltipHeight;
            } else if (direction === "bottom") {
              subX = tooltipWidth / 2;
              subY = 0;
            } else if (direction === "center") {
              subX = tooltipWidth / 2;
              subY = tooltipHeight / 2;
            } else if (direction === "right") {
              subX = 0;
              subY = tooltipHeight / 2;
            } else if (direction === "left") {
              subX = tooltipWidth;
              subY = tooltipHeight / 2;
            } else if (tooltipPoint.x < centerPoint.x) {
              direction = "right";
              subX = 0;
              subY = tooltipHeight / 2;
            } else {
              direction = "left";
              subX = tooltipWidth + (offset.x + anchor.x) * 2;
              subY = tooltipHeight / 2;
            }
            pos = pos.subtract(toPoint(subX, subY, true)).add(offset).add(anchor);
            removeClass(container, "leaflet-tooltip-right");
            removeClass(container, "leaflet-tooltip-left");
            removeClass(container, "leaflet-tooltip-top");
            removeClass(container, "leaflet-tooltip-bottom");
            addClass(container, "leaflet-tooltip-" + direction);
            setPosition(container, pos);
          },
          _updatePosition: function() {
            var pos = this._map.latLngToLayerPoint(this._latlng);
            this._setPosition(pos);
          },
          setOpacity: function(opacity) {
            this.options.opacity = opacity;
            if (this._container) {
              setOpacity(this._container, opacity);
            }
          },
          _animateZoom: function(e) {
            var pos = this._map._latLngToNewLayerPoint(this._latlng, e.zoom, e.center);
            this._setPosition(pos);
          },
          _getAnchor: function() {
            return toPoint(this._source && this._source._getTooltipAnchor && !this.options.sticky ? this._source._getTooltipAnchor() : [0, 0]);
          }
        });
        var tooltip = function(options, source) {
          return new Tooltip(options, source);
        };
        Map.include({
          openTooltip: function(tooltip2, latlng, options) {
            this._initOverlay(Tooltip, tooltip2, latlng, options).openOn(this);
            return this;
          },
          closeTooltip: function(tooltip2) {
            tooltip2.close();
            return this;
          }
        });
        Layer.include({
          bindTooltip: function(content, options) {
            if (this._tooltip && this.isTooltipOpen()) {
              this.unbindTooltip();
            }
            this._tooltip = this._initOverlay(Tooltip, this._tooltip, content, options);
            this._initTooltipInteractions();
            if (this._tooltip.options.permanent && this._map && this._map.hasLayer(this)) {
              this.openTooltip();
            }
            return this;
          },
          unbindTooltip: function() {
            if (this._tooltip) {
              this._initTooltipInteractions(true);
              this.closeTooltip();
              this._tooltip = null;
            }
            return this;
          },
          _initTooltipInteractions: function(remove2) {
            if (!remove2 && this._tooltipHandlersAdded) {
              return;
            }
            var onOff = remove2 ? "off" : "on", events = {
              remove: this.closeTooltip,
              move: this._moveTooltip
            };
            if (!this._tooltip.options.permanent) {
              events.mouseover = this._openTooltip;
              events.mouseout = this.closeTooltip;
              events.click = this._openTooltip;
            } else {
              events.add = this._openTooltip;
            }
            if (this._tooltip.options.sticky) {
              events.mousemove = this._moveTooltip;
            }
            this[onOff](events);
            this._tooltipHandlersAdded = !remove2;
          },
          openTooltip: function(latlng) {
            if (this._tooltip && this._tooltip._prepareOpen(latlng)) {
              this._tooltip.openOn(this._map);
            }
            return this;
          },
          closeTooltip: function() {
            if (this._tooltip) {
              return this._tooltip.close();
            }
          },
          toggleTooltip: function() {
            if (this._tooltip) {
              this._tooltip.toggle(this);
            }
            return this;
          },
          isTooltipOpen: function() {
            return this._tooltip.isOpen();
          },
          setTooltipContent: function(content) {
            if (this._tooltip) {
              this._tooltip.setContent(content);
            }
            return this;
          },
          getTooltip: function() {
            return this._tooltip;
          },
          _openTooltip: function(e) {
            if (!this._tooltip || !this._map || this._map.dragging && this._map.dragging.moving()) {
              return;
            }
            this._tooltip._source = e.layer || e.target;
            this.openTooltip(this._tooltip.options.sticky ? e.latlng : void 0);
          },
          _moveTooltip: function(e) {
            var latlng = e.latlng, containerPoint, layerPoint;
            if (this._tooltip.options.sticky && e.originalEvent) {
              containerPoint = this._map.mouseEventToContainerPoint(e.originalEvent);
              layerPoint = this._map.containerPointToLayerPoint(containerPoint);
              latlng = this._map.layerPointToLatLng(layerPoint);
            }
            this._tooltip.setLatLng(latlng);
          }
        });
        var DivIcon = Icon.extend({
          options: {
            iconSize: [12, 12],
            html: false,
            bgPos: null,
            className: "leaflet-div-icon"
          },
          createIcon: function(oldIcon) {
            var div = oldIcon && oldIcon.tagName === "DIV" ? oldIcon : document.createElement("div"), options = this.options;
            if (options.html instanceof Element) {
              empty(div);
              div.appendChild(options.html);
            } else {
              div.innerHTML = options.html !== false ? options.html : "";
            }
            if (options.bgPos) {
              var bgPos = toPoint(options.bgPos);
              div.style.backgroundPosition = -bgPos.x + "px " + -bgPos.y + "px";
            }
            this._setIconStyles(div, "icon");
            return div;
          },
          createShadow: function() {
            return null;
          }
        });
        function divIcon(options) {
          return new DivIcon(options);
        }
        Icon.Default = IconDefault;
        var GridLayer = Layer.extend({
          options: {
            tileSize: 256,
            opacity: 1,
            updateWhenIdle: Browser.mobile,
            updateWhenZooming: true,
            updateInterval: 200,
            zIndex: 1,
            bounds: null,
            minZoom: 0,
            maxZoom: void 0,
            maxNativeZoom: void 0,
            minNativeZoom: void 0,
            noWrap: false,
            pane: "tilePane",
            className: "",
            keepBuffer: 2
          },
          initialize: function(options) {
            setOptions(this, options);
          },
          onAdd: function() {
            this._initContainer();
            this._levels = {};
            this._tiles = {};
            this._resetView();
          },
          beforeAdd: function(map) {
            map._addZoomLimit(this);
          },
          onRemove: function(map) {
            this._removeAllTiles();
            remove(this._container);
            map._removeZoomLimit(this);
            this._container = null;
            this._tileZoom = void 0;
          },
          bringToFront: function() {
            if (this._map) {
              toFront(this._container);
              this._setAutoZIndex(Math.max);
            }
            return this;
          },
          bringToBack: function() {
            if (this._map) {
              toBack(this._container);
              this._setAutoZIndex(Math.min);
            }
            return this;
          },
          getContainer: function() {
            return this._container;
          },
          setOpacity: function(opacity) {
            this.options.opacity = opacity;
            this._updateOpacity();
            return this;
          },
          setZIndex: function(zIndex) {
            this.options.zIndex = zIndex;
            this._updateZIndex();
            return this;
          },
          isLoading: function() {
            return this._loading;
          },
          redraw: function() {
            if (this._map) {
              this._removeAllTiles();
              var tileZoom = this._clampZoom(this._map.getZoom());
              if (tileZoom !== this._tileZoom) {
                this._tileZoom = tileZoom;
                this._updateLevels();
              }
              this._update();
            }
            return this;
          },
          getEvents: function() {
            var events = {
              viewprereset: this._invalidateAll,
              viewreset: this._resetView,
              zoom: this._resetView,
              moveend: this._onMoveEnd
            };
            if (!this.options.updateWhenIdle) {
              if (!this._onMove) {
                this._onMove = throttle(this._onMoveEnd, this.options.updateInterval, this);
              }
              events.move = this._onMove;
            }
            if (this._zoomAnimated) {
              events.zoomanim = this._animateZoom;
            }
            return events;
          },
          createTile: function() {
            return document.createElement("div");
          },
          getTileSize: function() {
            var s = this.options.tileSize;
            return s instanceof Point ? s : new Point(s, s);
          },
          _updateZIndex: function() {
            if (this._container && this.options.zIndex !== void 0 && this.options.zIndex !== null) {
              this._container.style.zIndex = this.options.zIndex;
            }
          },
          _setAutoZIndex: function(compare) {
            var layers2 = this.getPane().children, edgeZIndex = -compare(-Infinity, Infinity);
            for (var i = 0, len = layers2.length, zIndex; i < len; i++) {
              zIndex = layers2[i].style.zIndex;
              if (layers2[i] !== this._container && zIndex) {
                edgeZIndex = compare(edgeZIndex, +zIndex);
              }
            }
            if (isFinite(edgeZIndex)) {
              this.options.zIndex = edgeZIndex + compare(-1, 1);
              this._updateZIndex();
            }
          },
          _updateOpacity: function() {
            if (!this._map) {
              return;
            }
            if (Browser.ielt9) {
              return;
            }
            setOpacity(this._container, this.options.opacity);
            var now = +new Date(), nextFrame = false, willPrune = false;
            for (var key in this._tiles) {
              var tile = this._tiles[key];
              if (!tile.current || !tile.loaded) {
                continue;
              }
              var fade = Math.min(1, (now - tile.loaded) / 200);
              setOpacity(tile.el, fade);
              if (fade < 1) {
                nextFrame = true;
              } else {
                if (tile.active) {
                  willPrune = true;
                } else {
                  this._onOpaqueTile(tile);
                }
                tile.active = true;
              }
            }
            if (willPrune && !this._noPrune) {
              this._pruneTiles();
            }
            if (nextFrame) {
              cancelAnimFrame(this._fadeFrame);
              this._fadeFrame = requestAnimFrame(this._updateOpacity, this);
            }
          },
          _onOpaqueTile: falseFn,
          _initContainer: function() {
            if (this._container) {
              return;
            }
            this._container = create$1("div", "leaflet-layer " + (this.options.className || ""));
            this._updateZIndex();
            if (this.options.opacity < 1) {
              this._updateOpacity();
            }
            this.getPane().appendChild(this._container);
          },
          _updateLevels: function() {
            var zoom2 = this._tileZoom, maxZoom = this.options.maxZoom;
            if (zoom2 === void 0) {
              return void 0;
            }
            for (var z in this._levels) {
              z = Number(z);
              if (this._levels[z].el.children.length || z === zoom2) {
                this._levels[z].el.style.zIndex = maxZoom - Math.abs(zoom2 - z);
                this._onUpdateLevel(z);
              } else {
                remove(this._levels[z].el);
                this._removeTilesAtZoom(z);
                this._onRemoveLevel(z);
                delete this._levels[z];
              }
            }
            var level = this._levels[zoom2], map = this._map;
            if (!level) {
              level = this._levels[zoom2] = {};
              level.el = create$1("div", "leaflet-tile-container leaflet-zoom-animated", this._container);
              level.el.style.zIndex = maxZoom;
              level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom2).round();
              level.zoom = zoom2;
              this._setZoomTransform(level, map.getCenter(), map.getZoom());
              falseFn(level.el.offsetWidth);
              this._onCreateLevel(level);
            }
            this._level = level;
            return level;
          },
          _onUpdateLevel: falseFn,
          _onRemoveLevel: falseFn,
          _onCreateLevel: falseFn,
          _pruneTiles: function() {
            if (!this._map) {
              return;
            }
            var key, tile;
            var zoom2 = this._map.getZoom();
            if (zoom2 > this.options.maxZoom || zoom2 < this.options.minZoom) {
              this._removeAllTiles();
              return;
            }
            for (key in this._tiles) {
              tile = this._tiles[key];
              tile.retain = tile.current;
            }
            for (key in this._tiles) {
              tile = this._tiles[key];
              if (tile.current && !tile.active) {
                var coords = tile.coords;
                if (!this._retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
                  this._retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
                }
              }
            }
            for (key in this._tiles) {
              if (!this._tiles[key].retain) {
                this._removeTile(key);
              }
            }
          },
          _removeTilesAtZoom: function(zoom2) {
            for (var key in this._tiles) {
              if (this._tiles[key].coords.z !== zoom2) {
                continue;
              }
              this._removeTile(key);
            }
          },
          _removeAllTiles: function() {
            for (var key in this._tiles) {
              this._removeTile(key);
            }
          },
          _invalidateAll: function() {
            for (var z in this._levels) {
              remove(this._levels[z].el);
              this._onRemoveLevel(Number(z));
              delete this._levels[z];
            }
            this._removeAllTiles();
            this._tileZoom = void 0;
          },
          _retainParent: function(x, y, z, minZoom) {
            var x2 = Math.floor(x / 2), y2 = Math.floor(y / 2), z2 = z - 1, coords2 = new Point(+x2, +y2);
            coords2.z = +z2;
            var key = this._tileCoordsToKey(coords2), tile = this._tiles[key];
            if (tile && tile.active) {
              tile.retain = true;
              return true;
            } else if (tile && tile.loaded) {
              tile.retain = true;
            }
            if (z2 > minZoom) {
              return this._retainParent(x2, y2, z2, minZoom);
            }
            return false;
          },
          _retainChildren: function(x, y, z, maxZoom) {
            for (var i = 2 * x; i < 2 * x + 2; i++) {
              for (var j = 2 * y; j < 2 * y + 2; j++) {
                var coords = new Point(i, j);
                coords.z = z + 1;
                var key = this._tileCoordsToKey(coords), tile = this._tiles[key];
                if (tile && tile.active) {
                  tile.retain = true;
                  continue;
                } else if (tile && tile.loaded) {
                  tile.retain = true;
                }
                if (z + 1 < maxZoom) {
                  this._retainChildren(i, j, z + 1, maxZoom);
                }
              }
            }
          },
          _resetView: function(e) {
            var animating = e && (e.pinch || e.flyTo);
            this._setView(this._map.getCenter(), this._map.getZoom(), animating, animating);
          },
          _animateZoom: function(e) {
            this._setView(e.center, e.zoom, true, e.noUpdate);
          },
          _clampZoom: function(zoom2) {
            var options = this.options;
            if (void 0 !== options.minNativeZoom && zoom2 < options.minNativeZoom) {
              return options.minNativeZoom;
            }
            if (void 0 !== options.maxNativeZoom && options.maxNativeZoom < zoom2) {
              return options.maxNativeZoom;
            }
            return zoom2;
          },
          _setView: function(center, zoom2, noPrune, noUpdate) {
            var tileZoom = Math.round(zoom2);
            if (this.options.maxZoom !== void 0 && tileZoom > this.options.maxZoom || this.options.minZoom !== void 0 && tileZoom < this.options.minZoom) {
              tileZoom = void 0;
            } else {
              tileZoom = this._clampZoom(tileZoom);
            }
            var tileZoomChanged = this.options.updateWhenZooming && tileZoom !== this._tileZoom;
            if (!noUpdate || tileZoomChanged) {
              this._tileZoom = tileZoom;
              if (this._abortLoading) {
                this._abortLoading();
              }
              this._updateLevels();
              this._resetGrid();
              if (tileZoom !== void 0) {
                this._update(center);
              }
              if (!noPrune) {
                this._pruneTiles();
              }
              this._noPrune = !!noPrune;
            }
            this._setZoomTransforms(center, zoom2);
          },
          _setZoomTransforms: function(center, zoom2) {
            for (var i in this._levels) {
              this._setZoomTransform(this._levels[i], center, zoom2);
            }
          },
          _setZoomTransform: function(level, center, zoom2) {
            var scale2 = this._map.getZoomScale(zoom2, level.zoom), translate = level.origin.multiplyBy(scale2).subtract(this._map._getNewPixelOrigin(center, zoom2)).round();
            if (Browser.any3d) {
              setTransform(level.el, translate, scale2);
            } else {
              setPosition(level.el, translate);
            }
          },
          _resetGrid: function() {
            var map = this._map, crs = map.options.crs, tileSize = this._tileSize = this.getTileSize(), tileZoom = this._tileZoom;
            var bounds = this._map.getPixelWorldBounds(this._tileZoom);
            if (bounds) {
              this._globalTileRange = this._pxBoundsToTileRange(bounds);
            }
            this._wrapX = crs.wrapLng && !this.options.noWrap && [
              Math.floor(map.project([0, crs.wrapLng[0]], tileZoom).x / tileSize.x),
              Math.ceil(map.project([0, crs.wrapLng[1]], tileZoom).x / tileSize.y)
            ];
            this._wrapY = crs.wrapLat && !this.options.noWrap && [
              Math.floor(map.project([crs.wrapLat[0], 0], tileZoom).y / tileSize.x),
              Math.ceil(map.project([crs.wrapLat[1], 0], tileZoom).y / tileSize.y)
            ];
          },
          _onMoveEnd: function() {
            if (!this._map || this._map._animatingZoom) {
              return;
            }
            this._update();
          },
          _getTiledPixelBounds: function(center) {
            var map = this._map, mapZoom = map._animatingZoom ? Math.max(map._animateToZoom, map.getZoom()) : map.getZoom(), scale2 = map.getZoomScale(mapZoom, this._tileZoom), pixelCenter = map.project(center, this._tileZoom).floor(), halfSize = map.getSize().divideBy(scale2 * 2);
            return new Bounds(pixelCenter.subtract(halfSize), pixelCenter.add(halfSize));
          },
          _update: function(center) {
            var map = this._map;
            if (!map) {
              return;
            }
            var zoom2 = this._clampZoom(map.getZoom());
            if (center === void 0) {
              center = map.getCenter();
            }
            if (this._tileZoom === void 0) {
              return;
            }
            var pixelBounds = this._getTiledPixelBounds(center), tileRange = this._pxBoundsToTileRange(pixelBounds), tileCenter = tileRange.getCenter(), queue = [], margin = this.options.keepBuffer, noPruneRange = new Bounds(
              tileRange.getBottomLeft().subtract([margin, -margin]),
              tileRange.getTopRight().add([margin, -margin])
            );
            if (!(isFinite(tileRange.min.x) && isFinite(tileRange.min.y) && isFinite(tileRange.max.x) && isFinite(tileRange.max.y))) {
              throw new Error("Attempted to load an infinite number of tiles");
            }
            for (var key in this._tiles) {
              var c = this._tiles[key].coords;
              if (c.z !== this._tileZoom || !noPruneRange.contains(new Point(c.x, c.y))) {
                this._tiles[key].current = false;
              }
            }
            if (Math.abs(zoom2 - this._tileZoom) > 1) {
              this._setView(center, zoom2);
              return;
            }
            for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
              for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
                var coords = new Point(i, j);
                coords.z = this._tileZoom;
                if (!this._isValidTile(coords)) {
                  continue;
                }
                var tile = this._tiles[this._tileCoordsToKey(coords)];
                if (tile) {
                  tile.current = true;
                } else {
                  queue.push(coords);
                }
              }
            }
            queue.sort(function(a, b) {
              return a.distanceTo(tileCenter) - b.distanceTo(tileCenter);
            });
            if (queue.length !== 0) {
              if (!this._loading) {
                this._loading = true;
                this.fire("loading");
              }
              var fragment = document.createDocumentFragment();
              for (i = 0; i < queue.length; i++) {
                this._addTile(queue[i], fragment);
              }
              this._level.el.appendChild(fragment);
            }
          },
          _isValidTile: function(coords) {
            var crs = this._map.options.crs;
            if (!crs.infinite) {
              var bounds = this._globalTileRange;
              if (!crs.wrapLng && (coords.x < bounds.min.x || coords.x > bounds.max.x) || !crs.wrapLat && (coords.y < bounds.min.y || coords.y > bounds.max.y)) {
                return false;
              }
            }
            if (!this.options.bounds) {
              return true;
            }
            var tileBounds = this._tileCoordsToBounds(coords);
            return toLatLngBounds(this.options.bounds).overlaps(tileBounds);
          },
          _keyToBounds: function(key) {
            return this._tileCoordsToBounds(this._keyToTileCoords(key));
          },
          _tileCoordsToNwSe: function(coords) {
            var map = this._map, tileSize = this.getTileSize(), nwPoint = coords.scaleBy(tileSize), sePoint = nwPoint.add(tileSize), nw = map.unproject(nwPoint, coords.z), se = map.unproject(sePoint, coords.z);
            return [nw, se];
          },
          _tileCoordsToBounds: function(coords) {
            var bp = this._tileCoordsToNwSe(coords), bounds = new LatLngBounds(bp[0], bp[1]);
            if (!this.options.noWrap) {
              bounds = this._map.wrapLatLngBounds(bounds);
            }
            return bounds;
          },
          _tileCoordsToKey: function(coords) {
            return coords.x + ":" + coords.y + ":" + coords.z;
          },
          _keyToTileCoords: function(key) {
            var k = key.split(":"), coords = new Point(+k[0], +k[1]);
            coords.z = +k[2];
            return coords;
          },
          _removeTile: function(key) {
            var tile = this._tiles[key];
            if (!tile) {
              return;
            }
            remove(tile.el);
            delete this._tiles[key];
            this.fire("tileunload", {
              tile: tile.el,
              coords: this._keyToTileCoords(key)
            });
          },
          _initTile: function(tile) {
            addClass(tile, "leaflet-tile");
            var tileSize = this.getTileSize();
            tile.style.width = tileSize.x + "px";
            tile.style.height = tileSize.y + "px";
            tile.onselectstart = falseFn;
            tile.onmousemove = falseFn;
            if (Browser.ielt9 && this.options.opacity < 1) {
              setOpacity(tile, this.options.opacity);
            }
          },
          _addTile: function(coords, container) {
            var tilePos = this._getTilePos(coords), key = this._tileCoordsToKey(coords);
            var tile = this.createTile(this._wrapCoords(coords), bind(this._tileReady, this, coords));
            this._initTile(tile);
            if (this.createTile.length < 2) {
              requestAnimFrame(bind(this._tileReady, this, coords, null, tile));
            }
            setPosition(tile, tilePos);
            this._tiles[key] = {
              el: tile,
              coords,
              current: true
            };
            container.appendChild(tile);
            this.fire("tileloadstart", {
              tile,
              coords
            });
          },
          _tileReady: function(coords, err, tile) {
            if (err) {
              this.fire("tileerror", {
                error: err,
                tile,
                coords
              });
            }
            var key = this._tileCoordsToKey(coords);
            tile = this._tiles[key];
            if (!tile) {
              return;
            }
            tile.loaded = +new Date();
            if (this._map._fadeAnimated) {
              setOpacity(tile.el, 0);
              cancelAnimFrame(this._fadeFrame);
              this._fadeFrame = requestAnimFrame(this._updateOpacity, this);
            } else {
              tile.active = true;
              this._pruneTiles();
            }
            if (!err) {
              addClass(tile.el, "leaflet-tile-loaded");
              this.fire("tileload", {
                tile: tile.el,
                coords
              });
            }
            if (this._noTilesToLoad()) {
              this._loading = false;
              this.fire("load");
              if (Browser.ielt9 || !this._map._fadeAnimated) {
                requestAnimFrame(this._pruneTiles, this);
              } else {
                setTimeout(bind(this._pruneTiles, this), 250);
              }
            }
          },
          _getTilePos: function(coords) {
            return coords.scaleBy(this.getTileSize()).subtract(this._level.origin);
          },
          _wrapCoords: function(coords) {
            var newCoords = new Point(
              this._wrapX ? wrapNum(coords.x, this._wrapX) : coords.x,
              this._wrapY ? wrapNum(coords.y, this._wrapY) : coords.y
            );
            newCoords.z = coords.z;
            return newCoords;
          },
          _pxBoundsToTileRange: function(bounds) {
            var tileSize = this.getTileSize();
            return new Bounds(
              bounds.min.unscaleBy(tileSize).floor(),
              bounds.max.unscaleBy(tileSize).ceil().subtract([1, 1])
            );
          },
          _noTilesToLoad: function() {
            for (var key in this._tiles) {
              if (!this._tiles[key].loaded) {
                return false;
              }
            }
            return true;
          }
        });
        function gridLayer(options) {
          return new GridLayer(options);
        }
        var TileLayer = GridLayer.extend({
          options: {
            minZoom: 0,
            maxZoom: 18,
            subdomains: "abc",
            errorTileUrl: "",
            zoomOffset: 0,
            tms: false,
            zoomReverse: false,
            detectRetina: false,
            crossOrigin: false,
            referrerPolicy: false
          },
          initialize: function(url, options) {
            this._url = url;
            options = setOptions(this, options);
            if (options.detectRetina && Browser.retina && options.maxZoom > 0) {
              options.tileSize = Math.floor(options.tileSize / 2);
              if (!options.zoomReverse) {
                options.zoomOffset++;
                options.maxZoom--;
              } else {
                options.zoomOffset--;
                options.minZoom++;
              }
              options.minZoom = Math.max(0, options.minZoom);
            }
            if (typeof options.subdomains === "string") {
              options.subdomains = options.subdomains.split("");
            }
            this.on("tileunload", this._onTileRemove);
          },
          setUrl: function(url, noRedraw) {
            if (this._url === url && noRedraw === void 0) {
              noRedraw = true;
            }
            this._url = url;
            if (!noRedraw) {
              this.redraw();
            }
            return this;
          },
          createTile: function(coords, done) {
            var tile = document.createElement("img");
            on(tile, "load", bind(this._tileOnLoad, this, done, tile));
            on(tile, "error", bind(this._tileOnError, this, done, tile));
            if (this.options.crossOrigin || this.options.crossOrigin === "") {
              tile.crossOrigin = this.options.crossOrigin === true ? "" : this.options.crossOrigin;
            }
            if (typeof this.options.referrerPolicy === "string") {
              tile.referrerPolicy = this.options.referrerPolicy;
            }
            tile.alt = "";
            tile.setAttribute("role", "presentation");
            tile.src = this.getTileUrl(coords);
            return tile;
          },
          getTileUrl: function(coords) {
            var data = {
              r: Browser.retina ? "@2x" : "",
              s: this._getSubdomain(coords),
              x: coords.x,
              y: coords.y,
              z: this._getZoomForUrl()
            };
            if (this._map && !this._map.options.crs.infinite) {
              var invertedY = this._globalTileRange.max.y - coords.y;
              if (this.options.tms) {
                data["y"] = invertedY;
              }
              data["-y"] = invertedY;
            }
            return template(this._url, extend(data, this.options));
          },
          _tileOnLoad: function(done, tile) {
            if (Browser.ielt9) {
              setTimeout(bind(done, this, null, tile), 0);
            } else {
              done(null, tile);
            }
          },
          _tileOnError: function(done, tile, e) {
            var errorUrl = this.options.errorTileUrl;
            if (errorUrl && tile.getAttribute("src") !== errorUrl) {
              tile.src = errorUrl;
            }
            done(e, tile);
          },
          _onTileRemove: function(e) {
            e.tile.onload = null;
          },
          _getZoomForUrl: function() {
            var zoom2 = this._tileZoom, maxZoom = this.options.maxZoom, zoomReverse = this.options.zoomReverse, zoomOffset = this.options.zoomOffset;
            if (zoomReverse) {
              zoom2 = maxZoom - zoom2;
            }
            return zoom2 + zoomOffset;
          },
          _getSubdomain: function(tilePoint) {
            var index2 = Math.abs(tilePoint.x + tilePoint.y) % this.options.subdomains.length;
            return this.options.subdomains[index2];
          },
          _abortLoading: function() {
            var i, tile;
            for (i in this._tiles) {
              if (this._tiles[i].coords.z !== this._tileZoom) {
                tile = this._tiles[i].el;
                tile.onload = falseFn;
                tile.onerror = falseFn;
                if (!tile.complete) {
                  tile.src = emptyImageUrl;
                  var coords = this._tiles[i].coords;
                  remove(tile);
                  delete this._tiles[i];
                  this.fire("tileabort", {
                    tile,
                    coords
                  });
                }
              }
            }
          },
          _removeTile: function(key) {
            var tile = this._tiles[key];
            if (!tile) {
              return;
            }
            tile.el.setAttribute("src", emptyImageUrl);
            return GridLayer.prototype._removeTile.call(this, key);
          },
          _tileReady: function(coords, err, tile) {
            if (!this._map || tile && tile.getAttribute("src") === emptyImageUrl) {
              return;
            }
            return GridLayer.prototype._tileReady.call(this, coords, err, tile);
          }
        });
        function tileLayer(url, options) {
          return new TileLayer(url, options);
        }
        var TileLayerWMS = TileLayer.extend({
          defaultWmsParams: {
            service: "WMS",
            request: "GetMap",
            layers: "",
            styles: "",
            format: "image/jpeg",
            transparent: false,
            version: "1.1.1"
          },
          options: {
            crs: null,
            uppercase: false
          },
          initialize: function(url, options) {
            this._url = url;
            var wmsParams = extend({}, this.defaultWmsParams);
            for (var i in options) {
              if (!(i in this.options)) {
                wmsParams[i] = options[i];
              }
            }
            options = setOptions(this, options);
            var realRetina = options.detectRetina && Browser.retina ? 2 : 1;
            var tileSize = this.getTileSize();
            wmsParams.width = tileSize.x * realRetina;
            wmsParams.height = tileSize.y * realRetina;
            this.wmsParams = wmsParams;
          },
          onAdd: function(map) {
            this._crs = this.options.crs || map.options.crs;
            this._wmsVersion = parseFloat(this.wmsParams.version);
            var projectionKey = this._wmsVersion >= 1.3 ? "crs" : "srs";
            this.wmsParams[projectionKey] = this._crs.code;
            TileLayer.prototype.onAdd.call(this, map);
          },
          getTileUrl: function(coords) {
            var tileBounds = this._tileCoordsToNwSe(coords), crs = this._crs, bounds = toBounds(crs.project(tileBounds[0]), crs.project(tileBounds[1])), min = bounds.min, max = bounds.max, bbox = (this._wmsVersion >= 1.3 && this._crs === EPSG4326 ? [min.y, min.x, max.y, max.x] : [min.x, min.y, max.x, max.y]).join(","), url = TileLayer.prototype.getTileUrl.call(this, coords);
            return url + getParamString(this.wmsParams, url, this.options.uppercase) + (this.options.uppercase ? "&BBOX=" : "&bbox=") + bbox;
          },
          setParams: function(params, noRedraw) {
            extend(this.wmsParams, params);
            if (!noRedraw) {
              this.redraw();
            }
            return this;
          }
        });
        function tileLayerWMS(url, options) {
          return new TileLayerWMS(url, options);
        }
        TileLayer.WMS = TileLayerWMS;
        tileLayer.wms = tileLayerWMS;
        var Renderer = Layer.extend({
          options: {
            padding: 0.1
          },
          initialize: function(options) {
            setOptions(this, options);
            stamp(this);
            this._layers = this._layers || {};
          },
          onAdd: function() {
            if (!this._container) {
              this._initContainer();
              if (this._zoomAnimated) {
                addClass(this._container, "leaflet-zoom-animated");
              }
            }
            this.getPane().appendChild(this._container);
            this._update();
            this.on("update", this._updatePaths, this);
          },
          onRemove: function() {
            this.off("update", this._updatePaths, this);
            this._destroyContainer();
          },
          getEvents: function() {
            var events = {
              viewreset: this._reset,
              zoom: this._onZoom,
              moveend: this._update,
              zoomend: this._onZoomEnd
            };
            if (this._zoomAnimated) {
              events.zoomanim = this._onAnimZoom;
            }
            return events;
          },
          _onAnimZoom: function(ev) {
            this._updateTransform(ev.center, ev.zoom);
          },
          _onZoom: function() {
            this._updateTransform(this._map.getCenter(), this._map.getZoom());
          },
          _updateTransform: function(center, zoom2) {
            var scale2 = this._map.getZoomScale(zoom2, this._zoom), viewHalf = this._map.getSize().multiplyBy(0.5 + this.options.padding), currentCenterPoint = this._map.project(this._center, zoom2), topLeftOffset = viewHalf.multiplyBy(-scale2).add(currentCenterPoint).subtract(this._map._getNewPixelOrigin(center, zoom2));
            if (Browser.any3d) {
              setTransform(this._container, topLeftOffset, scale2);
            } else {
              setPosition(this._container, topLeftOffset);
            }
          },
          _reset: function() {
            this._update();
            this._updateTransform(this._center, this._zoom);
            for (var id in this._layers) {
              this._layers[id]._reset();
            }
          },
          _onZoomEnd: function() {
            for (var id in this._layers) {
              this._layers[id]._project();
            }
          },
          _updatePaths: function() {
            for (var id in this._layers) {
              this._layers[id]._update();
            }
          },
          _update: function() {
            var p = this.options.padding, size = this._map.getSize(), min = this._map.containerPointToLayerPoint(size.multiplyBy(-p)).round();
            this._bounds = new Bounds(min, min.add(size.multiplyBy(1 + p * 2)).round());
            this._center = this._map.getCenter();
            this._zoom = this._map.getZoom();
          }
        });
        var Canvas = Renderer.extend({
          options: {
            tolerance: 0
          },
          getEvents: function() {
            var events = Renderer.prototype.getEvents.call(this);
            events.viewprereset = this._onViewPreReset;
            return events;
          },
          _onViewPreReset: function() {
            this._postponeUpdatePaths = true;
          },
          onAdd: function() {
            Renderer.prototype.onAdd.call(this);
            this._draw();
          },
          _initContainer: function() {
            var container = this._container = document.createElement("canvas");
            on(container, "mousemove", this._onMouseMove, this);
            on(container, "click dblclick mousedown mouseup contextmenu", this._onClick, this);
            on(container, "mouseout", this._handleMouseOut, this);
            container["_leaflet_disable_events"] = true;
            this._ctx = container.getContext("2d");
          },
          _destroyContainer: function() {
            cancelAnimFrame(this._redrawRequest);
            delete this._ctx;
            remove(this._container);
            off(this._container);
            delete this._container;
          },
          _updatePaths: function() {
            if (this._postponeUpdatePaths) {
              return;
            }
            var layer;
            this._redrawBounds = null;
            for (var id in this._layers) {
              layer = this._layers[id];
              layer._update();
            }
            this._redraw();
          },
          _update: function() {
            if (this._map._animatingZoom && this._bounds) {
              return;
            }
            Renderer.prototype._update.call(this);
            var b = this._bounds, container = this._container, size = b.getSize(), m = Browser.retina ? 2 : 1;
            setPosition(container, b.min);
            container.width = m * size.x;
            container.height = m * size.y;
            container.style.width = size.x + "px";
            container.style.height = size.y + "px";
            if (Browser.retina) {
              this._ctx.scale(2, 2);
            }
            this._ctx.translate(-b.min.x, -b.min.y);
            this.fire("update");
          },
          _reset: function() {
            Renderer.prototype._reset.call(this);
            if (this._postponeUpdatePaths) {
              this._postponeUpdatePaths = false;
              this._updatePaths();
            }
          },
          _initPath: function(layer) {
            this._updateDashArray(layer);
            this._layers[stamp(layer)] = layer;
            var order = layer._order = {
              layer,
              prev: this._drawLast,
              next: null
            };
            if (this._drawLast) {
              this._drawLast.next = order;
            }
            this._drawLast = order;
            this._drawFirst = this._drawFirst || this._drawLast;
          },
          _addPath: function(layer) {
            this._requestRedraw(layer);
          },
          _removePath: function(layer) {
            var order = layer._order;
            var next = order.next;
            var prev = order.prev;
            if (next) {
              next.prev = prev;
            } else {
              this._drawLast = prev;
            }
            if (prev) {
              prev.next = next;
            } else {
              this._drawFirst = next;
            }
            delete layer._order;
            delete this._layers[stamp(layer)];
            this._requestRedraw(layer);
          },
          _updatePath: function(layer) {
            this._extendRedrawBounds(layer);
            layer._project();
            layer._update();
            this._requestRedraw(layer);
          },
          _updateStyle: function(layer) {
            this._updateDashArray(layer);
            this._requestRedraw(layer);
          },
          _updateDashArray: function(layer) {
            if (typeof layer.options.dashArray === "string") {
              var parts = layer.options.dashArray.split(/[, ]+/), dashArray = [], dashValue, i;
              for (i = 0; i < parts.length; i++) {
                dashValue = Number(parts[i]);
                if (isNaN(dashValue)) {
                  return;
                }
                dashArray.push(dashValue);
              }
              layer.options._dashArray = dashArray;
            } else {
              layer.options._dashArray = layer.options.dashArray;
            }
          },
          _requestRedraw: function(layer) {
            if (!this._map) {
              return;
            }
            this._extendRedrawBounds(layer);
            this._redrawRequest = this._redrawRequest || requestAnimFrame(this._redraw, this);
          },
          _extendRedrawBounds: function(layer) {
            if (layer._pxBounds) {
              var padding = (layer.options.weight || 0) + 1;
              this._redrawBounds = this._redrawBounds || new Bounds();
              this._redrawBounds.extend(layer._pxBounds.min.subtract([padding, padding]));
              this._redrawBounds.extend(layer._pxBounds.max.add([padding, padding]));
            }
          },
          _redraw: function() {
            this._redrawRequest = null;
            if (this._redrawBounds) {
              this._redrawBounds.min._floor();
              this._redrawBounds.max._ceil();
            }
            this._clear();
            this._draw();
            this._redrawBounds = null;
          },
          _clear: function() {
            var bounds = this._redrawBounds;
            if (bounds) {
              var size = bounds.getSize();
              this._ctx.clearRect(bounds.min.x, bounds.min.y, size.x, size.y);
            } else {
              this._ctx.save();
              this._ctx.setTransform(1, 0, 0, 1, 0, 0);
              this._ctx.clearRect(0, 0, this._container.width, this._container.height);
              this._ctx.restore();
            }
          },
          _draw: function() {
            var layer, bounds = this._redrawBounds;
            this._ctx.save();
            if (bounds) {
              var size = bounds.getSize();
              this._ctx.beginPath();
              this._ctx.rect(bounds.min.x, bounds.min.y, size.x, size.y);
              this._ctx.clip();
            }
            this._drawing = true;
            for (var order = this._drawFirst; order; order = order.next) {
              layer = order.layer;
              if (!bounds || layer._pxBounds && layer._pxBounds.intersects(bounds)) {
                layer._updatePath();
              }
            }
            this._drawing = false;
            this._ctx.restore();
          },
          _updatePoly: function(layer, closed) {
            if (!this._drawing) {
              return;
            }
            var i, j, len2, p, parts = layer._parts, len = parts.length, ctx = this._ctx;
            if (!len) {
              return;
            }
            ctx.beginPath();
            for (i = 0; i < len; i++) {
              for (j = 0, len2 = parts[i].length; j < len2; j++) {
                p = parts[i][j];
                ctx[j ? "lineTo" : "moveTo"](p.x, p.y);
              }
              if (closed) {
                ctx.closePath();
              }
            }
            this._fillStroke(ctx, layer);
          },
          _updateCircle: function(layer) {
            if (!this._drawing || layer._empty()) {
              return;
            }
            var p = layer._point, ctx = this._ctx, r = Math.max(Math.round(layer._radius), 1), s = (Math.max(Math.round(layer._radiusY), 1) || r) / r;
            if (s !== 1) {
              ctx.save();
              ctx.scale(1, s);
            }
            ctx.beginPath();
            ctx.arc(p.x, p.y / s, r, 0, Math.PI * 2, false);
            if (s !== 1) {
              ctx.restore();
            }
            this._fillStroke(ctx, layer);
          },
          _fillStroke: function(ctx, layer) {
            var options = layer.options;
            if (options.fill) {
              ctx.globalAlpha = options.fillOpacity;
              ctx.fillStyle = options.fillColor || options.color;
              ctx.fill(options.fillRule || "evenodd");
            }
            if (options.stroke && options.weight !== 0) {
              if (ctx.setLineDash) {
                ctx.setLineDash(layer.options && layer.options._dashArray || []);
              }
              ctx.globalAlpha = options.opacity;
              ctx.lineWidth = options.weight;
              ctx.strokeStyle = options.color;
              ctx.lineCap = options.lineCap;
              ctx.lineJoin = options.lineJoin;
              ctx.stroke();
            }
          },
          _onClick: function(e) {
            var point = this._map.mouseEventToLayerPoint(e), layer, clickedLayer;
            for (var order = this._drawFirst; order; order = order.next) {
              layer = order.layer;
              if (layer.options.interactive && layer._containsPoint(point)) {
                if (!(e.type === "click" || e.type === "preclick") || !this._map._draggableMoved(layer)) {
                  clickedLayer = layer;
                }
              }
            }
            this._fireEvent(clickedLayer ? [clickedLayer] : false, e);
          },
          _onMouseMove: function(e) {
            if (!this._map || this._map.dragging.moving() || this._map._animatingZoom) {
              return;
            }
            var point = this._map.mouseEventToLayerPoint(e);
            this._handleMouseHover(e, point);
          },
          _handleMouseOut: function(e) {
            var layer = this._hoveredLayer;
            if (layer) {
              removeClass(this._container, "leaflet-interactive");
              this._fireEvent([layer], e, "mouseout");
              this._hoveredLayer = null;
              this._mouseHoverThrottled = false;
            }
          },
          _handleMouseHover: function(e, point) {
            if (this._mouseHoverThrottled) {
              return;
            }
            var layer, candidateHoveredLayer;
            for (var order = this._drawFirst; order; order = order.next) {
              layer = order.layer;
              if (layer.options.interactive && layer._containsPoint(point)) {
                candidateHoveredLayer = layer;
              }
            }
            if (candidateHoveredLayer !== this._hoveredLayer) {
              this._handleMouseOut(e);
              if (candidateHoveredLayer) {
                addClass(this._container, "leaflet-interactive");
                this._fireEvent([candidateHoveredLayer], e, "mouseover");
                this._hoveredLayer = candidateHoveredLayer;
              }
            }
            this._fireEvent(this._hoveredLayer ? [this._hoveredLayer] : false, e);
            this._mouseHoverThrottled = true;
            setTimeout(bind(function() {
              this._mouseHoverThrottled = false;
            }, this), 32);
          },
          _fireEvent: function(layers2, e, type) {
            this._map._fireDOMEvent(e, type || e.type, layers2);
          },
          _bringToFront: function(layer) {
            var order = layer._order;
            if (!order) {
              return;
            }
            var next = order.next;
            var prev = order.prev;
            if (next) {
              next.prev = prev;
            } else {
              return;
            }
            if (prev) {
              prev.next = next;
            } else if (next) {
              this._drawFirst = next;
            }
            order.prev = this._drawLast;
            this._drawLast.next = order;
            order.next = null;
            this._drawLast = order;
            this._requestRedraw(layer);
          },
          _bringToBack: function(layer) {
            var order = layer._order;
            if (!order) {
              return;
            }
            var next = order.next;
            var prev = order.prev;
            if (prev) {
              prev.next = next;
            } else {
              return;
            }
            if (next) {
              next.prev = prev;
            } else if (prev) {
              this._drawLast = prev;
            }
            order.prev = null;
            order.next = this._drawFirst;
            this._drawFirst.prev = order;
            this._drawFirst = order;
            this._requestRedraw(layer);
          }
        });
        function canvas(options) {
          return Browser.canvas ? new Canvas(options) : null;
        }
        var vmlCreate = function() {
          try {
            document.namespaces.add("lvml", "urn:schemas-microsoft-com:vml");
            return function(name) {
              return document.createElement("<lvml:" + name + ' class="lvml">');
            };
          } catch (e) {
          }
          return function(name) {
            return document.createElement("<" + name + ' xmlns="urn:schemas-microsoft.com:vml" class="lvml">');
          };
        }();
        var vmlMixin = {
          _initContainer: function() {
            this._container = create$1("div", "leaflet-vml-container");
          },
          _update: function() {
            if (this._map._animatingZoom) {
              return;
            }
            Renderer.prototype._update.call(this);
            this.fire("update");
          },
          _initPath: function(layer) {
            var container = layer._container = vmlCreate("shape");
            addClass(container, "leaflet-vml-shape " + (this.options.className || ""));
            container.coordsize = "1 1";
            layer._path = vmlCreate("path");
            container.appendChild(layer._path);
            this._updateStyle(layer);
            this._layers[stamp(layer)] = layer;
          },
          _addPath: function(layer) {
            var container = layer._container;
            this._container.appendChild(container);
            if (layer.options.interactive) {
              layer.addInteractiveTarget(container);
            }
          },
          _removePath: function(layer) {
            var container = layer._container;
            remove(container);
            layer.removeInteractiveTarget(container);
            delete this._layers[stamp(layer)];
          },
          _updateStyle: function(layer) {
            var stroke = layer._stroke, fill = layer._fill, options = layer.options, container = layer._container;
            container.stroked = !!options.stroke;
            container.filled = !!options.fill;
            if (options.stroke) {
              if (!stroke) {
                stroke = layer._stroke = vmlCreate("stroke");
              }
              container.appendChild(stroke);
              stroke.weight = options.weight + "px";
              stroke.color = options.color;
              stroke.opacity = options.opacity;
              if (options.dashArray) {
                stroke.dashStyle = isArray(options.dashArray) ? options.dashArray.join(" ") : options.dashArray.replace(/( *, *)/g, " ");
              } else {
                stroke.dashStyle = "";
              }
              stroke.endcap = options.lineCap.replace("butt", "flat");
              stroke.joinstyle = options.lineJoin;
            } else if (stroke) {
              container.removeChild(stroke);
              layer._stroke = null;
            }
            if (options.fill) {
              if (!fill) {
                fill = layer._fill = vmlCreate("fill");
              }
              container.appendChild(fill);
              fill.color = options.fillColor || options.color;
              fill.opacity = options.fillOpacity;
            } else if (fill) {
              container.removeChild(fill);
              layer._fill = null;
            }
          },
          _updateCircle: function(layer) {
            var p = layer._point.round(), r = Math.round(layer._radius), r2 = Math.round(layer._radiusY || r);
            this._setPath(layer, layer._empty() ? "M0 0" : "AL " + p.x + "," + p.y + " " + r + "," + r2 + " 0," + 65535 * 360);
          },
          _setPath: function(layer, path) {
            layer._path.v = path;
          },
          _bringToFront: function(layer) {
            toFront(layer._container);
          },
          _bringToBack: function(layer) {
            toBack(layer._container);
          }
        };
        var create = Browser.vml ? vmlCreate : svgCreate;
        var SVG = Renderer.extend({
          _initContainer: function() {
            this._container = create("svg");
            this._container.setAttribute("pointer-events", "none");
            this._rootGroup = create("g");
            this._container.appendChild(this._rootGroup);
          },
          _destroyContainer: function() {
            remove(this._container);
            off(this._container);
            delete this._container;
            delete this._rootGroup;
            delete this._svgSize;
          },
          _update: function() {
            if (this._map._animatingZoom && this._bounds) {
              return;
            }
            Renderer.prototype._update.call(this);
            var b = this._bounds, size = b.getSize(), container = this._container;
            if (!this._svgSize || !this._svgSize.equals(size)) {
              this._svgSize = size;
              container.setAttribute("width", size.x);
              container.setAttribute("height", size.y);
            }
            setPosition(container, b.min);
            container.setAttribute("viewBox", [b.min.x, b.min.y, size.x, size.y].join(" "));
            this.fire("update");
          },
          _initPath: function(layer) {
            var path = layer._path = create("path");
            if (layer.options.className) {
              addClass(path, layer.options.className);
            }
            if (layer.options.interactive) {
              addClass(path, "leaflet-interactive");
            }
            this._updateStyle(layer);
            this._layers[stamp(layer)] = layer;
          },
          _addPath: function(layer) {
            if (!this._rootGroup) {
              this._initContainer();
            }
            this._rootGroup.appendChild(layer._path);
            layer.addInteractiveTarget(layer._path);
          },
          _removePath: function(layer) {
            remove(layer._path);
            layer.removeInteractiveTarget(layer._path);
            delete this._layers[stamp(layer)];
          },
          _updatePath: function(layer) {
            layer._project();
            layer._update();
          },
          _updateStyle: function(layer) {
            var path = layer._path, options = layer.options;
            if (!path) {
              return;
            }
            if (options.stroke) {
              path.setAttribute("stroke", options.color);
              path.setAttribute("stroke-opacity", options.opacity);
              path.setAttribute("stroke-width", options.weight);
              path.setAttribute("stroke-linecap", options.lineCap);
              path.setAttribute("stroke-linejoin", options.lineJoin);
              if (options.dashArray) {
                path.setAttribute("stroke-dasharray", options.dashArray);
              } else {
                path.removeAttribute("stroke-dasharray");
              }
              if (options.dashOffset) {
                path.setAttribute("stroke-dashoffset", options.dashOffset);
              } else {
                path.removeAttribute("stroke-dashoffset");
              }
            } else {
              path.setAttribute("stroke", "none");
            }
            if (options.fill) {
              path.setAttribute("fill", options.fillColor || options.color);
              path.setAttribute("fill-opacity", options.fillOpacity);
              path.setAttribute("fill-rule", options.fillRule || "evenodd");
            } else {
              path.setAttribute("fill", "none");
            }
          },
          _updatePoly: function(layer, closed) {
            this._setPath(layer, pointsToPath(layer._parts, closed));
          },
          _updateCircle: function(layer) {
            var p = layer._point, r = Math.max(Math.round(layer._radius), 1), r2 = Math.max(Math.round(layer._radiusY), 1) || r, arc = "a" + r + "," + r2 + " 0 1,0 ";
            var d = layer._empty() ? "M0 0" : "M" + (p.x - r) + "," + p.y + arc + r * 2 + ",0 " + arc + -r * 2 + ",0 ";
            this._setPath(layer, d);
          },
          _setPath: function(layer, path) {
            layer._path.setAttribute("d", path);
          },
          _bringToFront: function(layer) {
            toFront(layer._path);
          },
          _bringToBack: function(layer) {
            toBack(layer._path);
          }
        });
        if (Browser.vml) {
          SVG.include(vmlMixin);
        }
        function svg(options) {
          return Browser.svg || Browser.vml ? new SVG(options) : null;
        }
        Map.include({
          getRenderer: function(layer) {
            var renderer = layer.options.renderer || this._getPaneRenderer(layer.options.pane) || this.options.renderer || this._renderer;
            if (!renderer) {
              renderer = this._renderer = this._createRenderer();
            }
            if (!this.hasLayer(renderer)) {
              this.addLayer(renderer);
            }
            return renderer;
          },
          _getPaneRenderer: function(name) {
            if (name === "overlayPane" || name === void 0) {
              return false;
            }
            var renderer = this._paneRenderers[name];
            if (renderer === void 0) {
              renderer = this._createRenderer({ pane: name });
              this._paneRenderers[name] = renderer;
            }
            return renderer;
          },
          _createRenderer: function(options) {
            return this.options.preferCanvas && canvas(options) || svg(options);
          }
        });
        var Rectangle = Polygon.extend({
          initialize: function(latLngBounds, options) {
            Polygon.prototype.initialize.call(this, this._boundsToLatLngs(latLngBounds), options);
          },
          setBounds: function(latLngBounds) {
            return this.setLatLngs(this._boundsToLatLngs(latLngBounds));
          },
          _boundsToLatLngs: function(latLngBounds) {
            latLngBounds = toLatLngBounds(latLngBounds);
            return [
              latLngBounds.getSouthWest(),
              latLngBounds.getNorthWest(),
              latLngBounds.getNorthEast(),
              latLngBounds.getSouthEast()
            ];
          }
        });
        function rectangle(latLngBounds, options) {
          return new Rectangle(latLngBounds, options);
        }
        SVG.create = create;
        SVG.pointsToPath = pointsToPath;
        GeoJSON.geometryToLayer = geometryToLayer;
        GeoJSON.coordsToLatLng = coordsToLatLng;
        GeoJSON.coordsToLatLngs = coordsToLatLngs;
        GeoJSON.latLngToCoords = latLngToCoords;
        GeoJSON.latLngsToCoords = latLngsToCoords;
        GeoJSON.getFeature = getFeature;
        GeoJSON.asFeature = asFeature;
        Map.mergeOptions({
          boxZoom: true
        });
        var BoxZoom = Handler.extend({
          initialize: function(map) {
            this._map = map;
            this._container = map._container;
            this._pane = map._panes.overlayPane;
            this._resetStateTimeout = 0;
            map.on("unload", this._destroy, this);
          },
          addHooks: function() {
            on(this._container, "mousedown", this._onMouseDown, this);
          },
          removeHooks: function() {
            off(this._container, "mousedown", this._onMouseDown, this);
          },
          moved: function() {
            return this._moved;
          },
          _destroy: function() {
            remove(this._pane);
            delete this._pane;
          },
          _resetState: function() {
            this._resetStateTimeout = 0;
            this._moved = false;
          },
          _clearDeferredResetState: function() {
            if (this._resetStateTimeout !== 0) {
              clearTimeout(this._resetStateTimeout);
              this._resetStateTimeout = 0;
            }
          },
          _onMouseDown: function(e) {
            if (!e.shiftKey || e.which !== 1 && e.button !== 1) {
              return false;
            }
            this._clearDeferredResetState();
            this._resetState();
            disableTextSelection();
            disableImageDrag();
            this._startPoint = this._map.mouseEventToContainerPoint(e);
            on(document, {
              contextmenu: stop,
              mousemove: this._onMouseMove,
              mouseup: this._onMouseUp,
              keydown: this._onKeyDown
            }, this);
          },
          _onMouseMove: function(e) {
            if (!this._moved) {
              this._moved = true;
              this._box = create$1("div", "leaflet-zoom-box", this._container);
              addClass(this._container, "leaflet-crosshair");
              this._map.fire("boxzoomstart");
            }
            this._point = this._map.mouseEventToContainerPoint(e);
            var bounds = new Bounds(this._point, this._startPoint), size = bounds.getSize();
            setPosition(this._box, bounds.min);
            this._box.style.width = size.x + "px";
            this._box.style.height = size.y + "px";
          },
          _finish: function() {
            if (this._moved) {
              remove(this._box);
              removeClass(this._container, "leaflet-crosshair");
            }
            enableTextSelection();
            enableImageDrag();
            off(document, {
              contextmenu: stop,
              mousemove: this._onMouseMove,
              mouseup: this._onMouseUp,
              keydown: this._onKeyDown
            }, this);
          },
          _onMouseUp: function(e) {
            if (e.which !== 1 && e.button !== 1) {
              return;
            }
            this._finish();
            if (!this._moved) {
              return;
            }
            this._clearDeferredResetState();
            this._resetStateTimeout = setTimeout(bind(this._resetState, this), 0);
            var bounds = new LatLngBounds(
              this._map.containerPointToLatLng(this._startPoint),
              this._map.containerPointToLatLng(this._point)
            );
            this._map.fitBounds(bounds).fire("boxzoomend", { boxZoomBounds: bounds });
          },
          _onKeyDown: function(e) {
            if (e.keyCode === 27) {
              this._finish();
              this._clearDeferredResetState();
              this._resetState();
            }
          }
        });
        Map.addInitHook("addHandler", "boxZoom", BoxZoom);
        Map.mergeOptions({
          doubleClickZoom: true
        });
        var DoubleClickZoom = Handler.extend({
          addHooks: function() {
            this._map.on("dblclick", this._onDoubleClick, this);
          },
          removeHooks: function() {
            this._map.off("dblclick", this._onDoubleClick, this);
          },
          _onDoubleClick: function(e) {
            var map = this._map, oldZoom = map.getZoom(), delta = map.options.zoomDelta, zoom2 = e.originalEvent.shiftKey ? oldZoom - delta : oldZoom + delta;
            if (map.options.doubleClickZoom === "center") {
              map.setZoom(zoom2);
            } else {
              map.setZoomAround(e.containerPoint, zoom2);
            }
          }
        });
        Map.addInitHook("addHandler", "doubleClickZoom", DoubleClickZoom);
        Map.mergeOptions({
          dragging: true,
          inertia: true,
          inertiaDeceleration: 3400,
          inertiaMaxSpeed: Infinity,
          easeLinearity: 0.2,
          worldCopyJump: false,
          maxBoundsViscosity: 0
        });
        var Drag = Handler.extend({
          addHooks: function() {
            if (!this._draggable) {
              var map = this._map;
              this._draggable = new Draggable(map._mapPane, map._container);
              this._draggable.on({
                dragstart: this._onDragStart,
                drag: this._onDrag,
                dragend: this._onDragEnd
              }, this);
              this._draggable.on("predrag", this._onPreDragLimit, this);
              if (map.options.worldCopyJump) {
                this._draggable.on("predrag", this._onPreDragWrap, this);
                map.on("zoomend", this._onZoomEnd, this);
                map.whenReady(this._onZoomEnd, this);
              }
            }
            addClass(this._map._container, "leaflet-grab leaflet-touch-drag");
            this._draggable.enable();
            this._positions = [];
            this._times = [];
          },
          removeHooks: function() {
            removeClass(this._map._container, "leaflet-grab");
            removeClass(this._map._container, "leaflet-touch-drag");
            this._draggable.disable();
          },
          moved: function() {
            return this._draggable && this._draggable._moved;
          },
          moving: function() {
            return this._draggable && this._draggable._moving;
          },
          _onDragStart: function() {
            var map = this._map;
            map._stop();
            if (this._map.options.maxBounds && this._map.options.maxBoundsViscosity) {
              var bounds = toLatLngBounds(this._map.options.maxBounds);
              this._offsetLimit = toBounds(
                this._map.latLngToContainerPoint(bounds.getNorthWest()).multiplyBy(-1),
                this._map.latLngToContainerPoint(bounds.getSouthEast()).multiplyBy(-1).add(this._map.getSize())
              );
              this._viscosity = Math.min(1, Math.max(0, this._map.options.maxBoundsViscosity));
            } else {
              this._offsetLimit = null;
            }
            map.fire("movestart").fire("dragstart");
            if (map.options.inertia) {
              this._positions = [];
              this._times = [];
            }
          },
          _onDrag: function(e) {
            if (this._map.options.inertia) {
              var time = this._lastTime = +new Date(), pos = this._lastPos = this._draggable._absPos || this._draggable._newPos;
              this._positions.push(pos);
              this._times.push(time);
              this._prunePositions(time);
            }
            this._map.fire("move", e).fire("drag", e);
          },
          _prunePositions: function(time) {
            while (this._positions.length > 1 && time - this._times[0] > 50) {
              this._positions.shift();
              this._times.shift();
            }
          },
          _onZoomEnd: function() {
            var pxCenter = this._map.getSize().divideBy(2), pxWorldCenter = this._map.latLngToLayerPoint([0, 0]);
            this._initialWorldOffset = pxWorldCenter.subtract(pxCenter).x;
            this._worldWidth = this._map.getPixelWorldBounds().getSize().x;
          },
          _viscousLimit: function(value, threshold) {
            return value - (value - threshold) * this._viscosity;
          },
          _onPreDragLimit: function() {
            if (!this._viscosity || !this._offsetLimit) {
              return;
            }
            var offset = this._draggable._newPos.subtract(this._draggable._startPos);
            var limit = this._offsetLimit;
            if (offset.x < limit.min.x) {
              offset.x = this._viscousLimit(offset.x, limit.min.x);
            }
            if (offset.y < limit.min.y) {
              offset.y = this._viscousLimit(offset.y, limit.min.y);
            }
            if (offset.x > limit.max.x) {
              offset.x = this._viscousLimit(offset.x, limit.max.x);
            }
            if (offset.y > limit.max.y) {
              offset.y = this._viscousLimit(offset.y, limit.max.y);
            }
            this._draggable._newPos = this._draggable._startPos.add(offset);
          },
          _onPreDragWrap: function() {
            var worldWidth = this._worldWidth, halfWidth = Math.round(worldWidth / 2), dx = this._initialWorldOffset, x = this._draggable._newPos.x, newX1 = (x - halfWidth + dx) % worldWidth + halfWidth - dx, newX2 = (x + halfWidth + dx) % worldWidth - halfWidth - dx, newX = Math.abs(newX1 + dx) < Math.abs(newX2 + dx) ? newX1 : newX2;
            this._draggable._absPos = this._draggable._newPos.clone();
            this._draggable._newPos.x = newX;
          },
          _onDragEnd: function(e) {
            var map = this._map, options = map.options, noInertia = !options.inertia || e.noInertia || this._times.length < 2;
            map.fire("dragend", e);
            if (noInertia) {
              map.fire("moveend");
            } else {
              this._prunePositions(+new Date());
              var direction = this._lastPos.subtract(this._positions[0]), duration = (this._lastTime - this._times[0]) / 1e3, ease = options.easeLinearity, speedVector = direction.multiplyBy(ease / duration), speed = speedVector.distanceTo([0, 0]), limitedSpeed = Math.min(options.inertiaMaxSpeed, speed), limitedSpeedVector = speedVector.multiplyBy(limitedSpeed / speed), decelerationDuration = limitedSpeed / (options.inertiaDeceleration * ease), offset = limitedSpeedVector.multiplyBy(-decelerationDuration / 2).round();
              if (!offset.x && !offset.y) {
                map.fire("moveend");
              } else {
                offset = map._limitOffset(offset, map.options.maxBounds);
                requestAnimFrame(function() {
                  map.panBy(offset, {
                    duration: decelerationDuration,
                    easeLinearity: ease,
                    noMoveStart: true,
                    animate: true
                  });
                });
              }
            }
          }
        });
        Map.addInitHook("addHandler", "dragging", Drag);
        Map.mergeOptions({
          keyboard: true,
          keyboardPanDelta: 80
        });
        var Keyboard = Handler.extend({
          keyCodes: {
            left: [37],
            right: [39],
            down: [40],
            up: [38],
            zoomIn: [187, 107, 61, 171],
            zoomOut: [189, 109, 54, 173]
          },
          initialize: function(map) {
            this._map = map;
            this._setPanDelta(map.options.keyboardPanDelta);
            this._setZoomDelta(map.options.zoomDelta);
          },
          addHooks: function() {
            var container = this._map._container;
            if (container.tabIndex <= 0) {
              container.tabIndex = "0";
            }
            on(container, {
              focus: this._onFocus,
              blur: this._onBlur,
              mousedown: this._onMouseDown
            }, this);
            this._map.on({
              focus: this._addHooks,
              blur: this._removeHooks
            }, this);
          },
          removeHooks: function() {
            this._removeHooks();
            off(this._map._container, {
              focus: this._onFocus,
              blur: this._onBlur,
              mousedown: this._onMouseDown
            }, this);
            this._map.off({
              focus: this._addHooks,
              blur: this._removeHooks
            }, this);
          },
          _onMouseDown: function() {
            if (this._focused) {
              return;
            }
            var body = document.body, docEl = document.documentElement, top = body.scrollTop || docEl.scrollTop, left = body.scrollLeft || docEl.scrollLeft;
            this._map._container.focus();
            window.scrollTo(left, top);
          },
          _onFocus: function() {
            this._focused = true;
            this._map.fire("focus");
          },
          _onBlur: function() {
            this._focused = false;
            this._map.fire("blur");
          },
          _setPanDelta: function(panDelta) {
            var keys = this._panKeys = {}, codes = this.keyCodes, i, len;
            for (i = 0, len = codes.left.length; i < len; i++) {
              keys[codes.left[i]] = [-1 * panDelta, 0];
            }
            for (i = 0, len = codes.right.length; i < len; i++) {
              keys[codes.right[i]] = [panDelta, 0];
            }
            for (i = 0, len = codes.down.length; i < len; i++) {
              keys[codes.down[i]] = [0, panDelta];
            }
            for (i = 0, len = codes.up.length; i < len; i++) {
              keys[codes.up[i]] = [0, -1 * panDelta];
            }
          },
          _setZoomDelta: function(zoomDelta) {
            var keys = this._zoomKeys = {}, codes = this.keyCodes, i, len;
            for (i = 0, len = codes.zoomIn.length; i < len; i++) {
              keys[codes.zoomIn[i]] = zoomDelta;
            }
            for (i = 0, len = codes.zoomOut.length; i < len; i++) {
              keys[codes.zoomOut[i]] = -zoomDelta;
            }
          },
          _addHooks: function() {
            on(document, "keydown", this._onKeyDown, this);
          },
          _removeHooks: function() {
            off(document, "keydown", this._onKeyDown, this);
          },
          _onKeyDown: function(e) {
            if (e.altKey || e.ctrlKey || e.metaKey) {
              return;
            }
            var key = e.keyCode, map = this._map, offset;
            if (key in this._panKeys) {
              if (!map._panAnim || !map._panAnim._inProgress) {
                offset = this._panKeys[key];
                if (e.shiftKey) {
                  offset = toPoint(offset).multiplyBy(3);
                }
                map.panBy(offset);
                if (map.options.maxBounds) {
                  map.panInsideBounds(map.options.maxBounds);
                }
              }
            } else if (key in this._zoomKeys) {
              map.setZoom(map.getZoom() + (e.shiftKey ? 3 : 1) * this._zoomKeys[key]);
            } else if (key === 27 && map._popup && map._popup.options.closeOnEscapeKey) {
              map.closePopup();
            } else {
              return;
            }
            stop(e);
          }
        });
        Map.addInitHook("addHandler", "keyboard", Keyboard);
        Map.mergeOptions({
          scrollWheelZoom: true,
          wheelDebounceTime: 40,
          wheelPxPerZoomLevel: 60
        });
        var ScrollWheelZoom = Handler.extend({
          addHooks: function() {
            on(this._map._container, "wheel", this._onWheelScroll, this);
            this._delta = 0;
          },
          removeHooks: function() {
            off(this._map._container, "wheel", this._onWheelScroll, this);
          },
          _onWheelScroll: function(e) {
            var delta = getWheelDelta(e);
            var debounce = this._map.options.wheelDebounceTime;
            this._delta += delta;
            this._lastMousePos = this._map.mouseEventToContainerPoint(e);
            if (!this._startTime) {
              this._startTime = +new Date();
            }
            var left = Math.max(debounce - (+new Date() - this._startTime), 0);
            clearTimeout(this._timer);
            this._timer = setTimeout(bind(this._performZoom, this), left);
            stop(e);
          },
          _performZoom: function() {
            var map = this._map, zoom2 = map.getZoom(), snap = this._map.options.zoomSnap || 0;
            map._stop();
            var d2 = this._delta / (this._map.options.wheelPxPerZoomLevel * 4), d3 = 4 * Math.log(2 / (1 + Math.exp(-Math.abs(d2)))) / Math.LN2, d4 = snap ? Math.ceil(d3 / snap) * snap : d3, delta = map._limitZoom(zoom2 + (this._delta > 0 ? d4 : -d4)) - zoom2;
            this._delta = 0;
            this._startTime = null;
            if (!delta) {
              return;
            }
            if (map.options.scrollWheelZoom === "center") {
              map.setZoom(zoom2 + delta);
            } else {
              map.setZoomAround(this._lastMousePos, zoom2 + delta);
            }
          }
        });
        Map.addInitHook("addHandler", "scrollWheelZoom", ScrollWheelZoom);
        var tapHoldDelay = 600;
        Map.mergeOptions({
          tapHold: Browser.touchNative && Browser.safari && Browser.mobile,
          tapTolerance: 15
        });
        var TapHold = Handler.extend({
          addHooks: function() {
            on(this._map._container, "touchstart", this._onDown, this);
          },
          removeHooks: function() {
            off(this._map._container, "touchstart", this._onDown, this);
          },
          _onDown: function(e) {
            clearTimeout(this._holdTimeout);
            if (e.touches.length !== 1) {
              return;
            }
            var first = e.touches[0];
            this._startPos = this._newPos = new Point(first.clientX, first.clientY);
            this._holdTimeout = setTimeout(bind(function() {
              this._cancel();
              if (!this._isTapValid()) {
                return;
              }
              on(document, "touchend", preventDefault);
              on(document, "touchend touchcancel", this._cancelClickPrevent);
              this._simulateEvent("contextmenu", first);
            }, this), tapHoldDelay);
            on(document, "touchend touchcancel contextmenu", this._cancel, this);
            on(document, "touchmove", this._onMove, this);
          },
          _cancelClickPrevent: function cancelClickPrevent() {
            off(document, "touchend", preventDefault);
            off(document, "touchend touchcancel", cancelClickPrevent);
          },
          _cancel: function() {
            clearTimeout(this._holdTimeout);
            off(document, "touchend touchcancel contextmenu", this._cancel, this);
            off(document, "touchmove", this._onMove, this);
          },
          _onMove: function(e) {
            var first = e.touches[0];
            this._newPos = new Point(first.clientX, first.clientY);
          },
          _isTapValid: function() {
            return this._newPos.distanceTo(this._startPos) <= this._map.options.tapTolerance;
          },
          _simulateEvent: function(type, e) {
            var simulatedEvent = new MouseEvent(type, {
              bubbles: true,
              cancelable: true,
              view: window,
              screenX: e.screenX,
              screenY: e.screenY,
              clientX: e.clientX,
              clientY: e.clientY
            });
            simulatedEvent._simulated = true;
            e.target.dispatchEvent(simulatedEvent);
          }
        });
        Map.addInitHook("addHandler", "tapHold", TapHold);
        Map.mergeOptions({
          touchZoom: Browser.touch,
          bounceAtZoomLimits: true
        });
        var TouchZoom = Handler.extend({
          addHooks: function() {
            addClass(this._map._container, "leaflet-touch-zoom");
            on(this._map._container, "touchstart", this._onTouchStart, this);
          },
          removeHooks: function() {
            removeClass(this._map._container, "leaflet-touch-zoom");
            off(this._map._container, "touchstart", this._onTouchStart, this);
          },
          _onTouchStart: function(e) {
            var map = this._map;
            if (!e.touches || e.touches.length !== 2 || map._animatingZoom || this._zooming) {
              return;
            }
            var p1 = map.mouseEventToContainerPoint(e.touches[0]), p2 = map.mouseEventToContainerPoint(e.touches[1]);
            this._centerPoint = map.getSize()._divideBy(2);
            this._startLatLng = map.containerPointToLatLng(this._centerPoint);
            if (map.options.touchZoom !== "center") {
              this._pinchStartLatLng = map.containerPointToLatLng(p1.add(p2)._divideBy(2));
            }
            this._startDist = p1.distanceTo(p2);
            this._startZoom = map.getZoom();
            this._moved = false;
            this._zooming = true;
            map._stop();
            on(document, "touchmove", this._onTouchMove, this);
            on(document, "touchend touchcancel", this._onTouchEnd, this);
            preventDefault(e);
          },
          _onTouchMove: function(e) {
            if (!e.touches || e.touches.length !== 2 || !this._zooming) {
              return;
            }
            var map = this._map, p1 = map.mouseEventToContainerPoint(e.touches[0]), p2 = map.mouseEventToContainerPoint(e.touches[1]), scale2 = p1.distanceTo(p2) / this._startDist;
            this._zoom = map.getScaleZoom(scale2, this._startZoom);
            if (!map.options.bounceAtZoomLimits && (this._zoom < map.getMinZoom() && scale2 < 1 || this._zoom > map.getMaxZoom() && scale2 > 1)) {
              this._zoom = map._limitZoom(this._zoom);
            }
            if (map.options.touchZoom === "center") {
              this._center = this._startLatLng;
              if (scale2 === 1) {
                return;
              }
            } else {
              var delta = p1._add(p2)._divideBy(2)._subtract(this._centerPoint);
              if (scale2 === 1 && delta.x === 0 && delta.y === 0) {
                return;
              }
              this._center = map.unproject(map.project(this._pinchStartLatLng, this._zoom).subtract(delta), this._zoom);
            }
            if (!this._moved) {
              map._moveStart(true, false);
              this._moved = true;
            }
            cancelAnimFrame(this._animRequest);
            var moveFn = bind(map._move, map, this._center, this._zoom, { pinch: true, round: false });
            this._animRequest = requestAnimFrame(moveFn, this, true);
            preventDefault(e);
          },
          _onTouchEnd: function() {
            if (!this._moved || !this._zooming) {
              this._zooming = false;
              return;
            }
            this._zooming = false;
            cancelAnimFrame(this._animRequest);
            off(document, "touchmove", this._onTouchMove, this);
            off(document, "touchend touchcancel", this._onTouchEnd, this);
            if (this._map.options.zoomAnimation) {
              this._map._animateZoom(this._center, this._map._limitZoom(this._zoom), true, this._map.options.zoomSnap);
            } else {
              this._map._resetView(this._center, this._map._limitZoom(this._zoom));
            }
          }
        });
        Map.addInitHook("addHandler", "touchZoom", TouchZoom);
        Map.BoxZoom = BoxZoom;
        Map.DoubleClickZoom = DoubleClickZoom;
        Map.Drag = Drag;
        Map.Keyboard = Keyboard;
        Map.ScrollWheelZoom = ScrollWheelZoom;
        Map.TapHold = TapHold;
        Map.TouchZoom = TouchZoom;
        exports2.Bounds = Bounds;
        exports2.Browser = Browser;
        exports2.CRS = CRS;
        exports2.Canvas = Canvas;
        exports2.Circle = Circle;
        exports2.CircleMarker = CircleMarker;
        exports2.Class = Class;
        exports2.Control = Control;
        exports2.DivIcon = DivIcon;
        exports2.DivOverlay = DivOverlay;
        exports2.DomEvent = DomEvent;
        exports2.DomUtil = DomUtil;
        exports2.Draggable = Draggable;
        exports2.Evented = Evented;
        exports2.FeatureGroup = FeatureGroup;
        exports2.GeoJSON = GeoJSON;
        exports2.GridLayer = GridLayer;
        exports2.Handler = Handler;
        exports2.Icon = Icon;
        exports2.ImageOverlay = ImageOverlay;
        exports2.LatLng = LatLng;
        exports2.LatLngBounds = LatLngBounds;
        exports2.Layer = Layer;
        exports2.LayerGroup = LayerGroup;
        exports2.LineUtil = LineUtil;
        exports2.Map = Map;
        exports2.Marker = Marker;
        exports2.Mixin = Mixin;
        exports2.Path = Path;
        exports2.Point = Point;
        exports2.PolyUtil = PolyUtil;
        exports2.Polygon = Polygon;
        exports2.Polyline = Polyline;
        exports2.Popup = Popup;
        exports2.PosAnimation = PosAnimation;
        exports2.Projection = index;
        exports2.Rectangle = Rectangle;
        exports2.Renderer = Renderer;
        exports2.SVG = SVG;
        exports2.SVGOverlay = SVGOverlay;
        exports2.TileLayer = TileLayer;
        exports2.Tooltip = Tooltip;
        exports2.Transformation = Transformation;
        exports2.Util = Util;
        exports2.VideoOverlay = VideoOverlay;
        exports2.bind = bind;
        exports2.bounds = toBounds;
        exports2.canvas = canvas;
        exports2.circle = circle;
        exports2.circleMarker = circleMarker;
        exports2.control = control;
        exports2.divIcon = divIcon;
        exports2.extend = extend;
        exports2.featureGroup = featureGroup;
        exports2.geoJSON = geoJSON;
        exports2.geoJson = geoJson;
        exports2.gridLayer = gridLayer;
        exports2.icon = icon;
        exports2.imageOverlay = imageOverlay;
        exports2.latLng = toLatLng;
        exports2.latLngBounds = toLatLngBounds;
        exports2.layerGroup = layerGroup;
        exports2.map = createMap;
        exports2.marker = marker;
        exports2.point = toPoint;
        exports2.polygon = polygon;
        exports2.polyline = polyline;
        exports2.popup = popup;
        exports2.rectangle = rectangle;
        exports2.setOptions = setOptions;
        exports2.stamp = stamp;
        exports2.svg = svg;
        exports2.svgOverlay = svgOverlay;
        exports2.tileLayer = tileLayer;
        exports2.tooltip = tooltip;
        exports2.transformation = toTransformation;
        exports2.version = version;
        exports2.videoOverlay = videoOverlay;
        var oldL = window.L;
        exports2.noConflict = function() {
          window.L = oldL;
          return this;
        };
        window.L = exports2;
      });
    }
  });

  // app/javascript/viewer/cdl_timer.js
  var CDLTimer = class {
    constructor(figgyId) {
      this.figgyId = figgyId;
    }
    async initializeTimer() {
      try {
        this.status = await this.fetchStatus();
        if (this.status.charged === false) {
          return;
        }
        this.setupReturnForm();
        const uvPane = document.getElementById("uv").firstChild;
        uvPane.insertBefore(this.returnButton(), uvPane.firstChild);
        await this.checkTime();
        window.setInterval(() => {
          this.checkTime();
        }, 1e3);
      } catch (e) {
      }
    }
    setupReturnForm() {
      const formAction = `/cdl/${this.figgyId}/return`;
      const form = document.getElementById("return-early-form");
      form.setAttribute("action", formAction);
      form.lastElementChild.setAttribute("value", this.figgyId);
    }
    returnButton() {
      const buttonElement = document.createElement("div");
      buttonElement.setAttribute("id", "cdl-viewer");
      const html = `<div id="return-early-button"><input type="submit" value="Return this item" class="btn btn-primary" form="return-early-form"></div>`;
      buttonElement.innerHTML = html;
      return buttonElement;
    }
    async checkTime() {
      const remainingTime = this.status.expires_at - this.currentTime;
      if (remainingTime <= 0) {
        return this.exitViewer();
      } else {
        this.setTime(remainingTime);
      }
    }
    setTime(remainingTime) {
      const oldElement = document.getElementById("remaining-time");
      if (oldElement !== null) {
        oldElement.parentNode.removeChild(oldElement);
      }
      const timeElement = document.createElement("div");
      timeElement.setAttribute("id", "remaining-time");
      timeElement.innerHTML = this.timeString(remainingTime);
      const buttonElement = document.getElementById("return-early-button");
      buttonElement.parentNode.insertBefore(timeElement, buttonElement.nextSibling);
    }
    timeString(remainingSeconds) {
      if (remainingSeconds > 300) {
        return `Expires At: ${this.localExpireTime}`;
      } else {
        return `Remaining Checkout Time: ${this.remainingTimeString(remainingSeconds)}`;
      }
    }
    get localExpireTime() {
      const expiresDate = new Date(this.status.expires_at * 1e3);
      return expiresDate.toLocaleTimeString();
    }
    remainingTimeString(seconds) {
      return new Date(seconds * 1e3).toISOString().substr(11, 8);
    }
    exitViewer() {
      window.location.reload();
    }
    get currentTime() {
      return Math.round(Date.now() / 1e3);
    }
    okCheck(response) {
      if (response.ok === true) {
        return response;
      }
      return Promise.reject(response);
    }
    async fetchStatus() {
      return fetch(`/cdl/${this.figgyId}/status`).then(this.okCheck).then((response) => response.json());
    }
  };

  // app/javascript/images/iiif-logo.svg
  var iiif_logo_default = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 493.36 441.333" height="441.333" width="493.36" xml:space="preserve" version="1.1"><metadata><rdf:RDF><cc:Work rdf:about=""><dc:format>image/svg+xml</dc:format><dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/></cc:Work></rdf:RDF></metadata><defs/><path d="M8.7 150.833L103.365 186l-.167 253.333L8.7 404.5V150.833" fill="#2873ab" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/><path d="M107.22 89.32c10.858 32.123-3.53 58.16-32.14 58.16-28.607 0-60.6-26.037-71.46-58.16-10.857-32.117 3.53-58.156 32.14-58.156 28.608 0 60.6 26.04 71.46 58.157" fill="#2873ab" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/><path d="M223.81 150.833L129.145 186l.166 253.333 94.5-34.833V150.833" fill="#ed1d33" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/><path d="M124.678 89.32c-10.86 32.123 3.53 58.16 32.138 58.16 28.608 0 60.6-26.037 71.46-58.16 10.86-32.117-3.53-58.156-32.137-58.156-28.61 0-60.604 26.04-71.462 58.157" fill="#ed1d33" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/><path d="M248.032 150.833L342.7 186l-.168 253.333-94.5-34.833V150.833" fill="#2873ab" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/><path d="M347.165 89.32c10.86 32.123-3.53 58.16-32.137 58.16-28.61 0-60.603-26.037-71.46-58.16-10.86-32.117 3.53-58.156 32.136-58.156 28.61 0 60.6 26.04 71.46 58.157" fill="#2873ab" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/><path d="M493.365 0v87s-30.666-12-34.333 19c-.333 33 0 44.833 0 44.833l34.333-11.166V216l-34.48 12.333v178l-94.186 35V126.667S362.7 13.333 493.364 0" fill="#ed1d33" fill-opacity="1" fill-rule="nonzero" stroke="none" stroke-width=".13333"/></svg>';

  // app/javascript/images/statement.png
  var statement_default = __toBinary("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");

  // app/javascript/images/copyright.svg
  var copyright_default = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"\n	 viewBox="0 0 24 24" style="enable-background:new 0 0 24 24;" xml:space="preserve">\n<style type="text/css">\n	.st0{fill:none;stroke:#FFFFFF;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}\n</style>\n<g>\n	<circle class="st0" cx="10" cy="15" r="5.5"/>\n	<path class="st0" d="M19.5,23.5h-19v-23h13l6,6V23.5z M13.5,0.5v6h6 M11.2,13.7c-0.2-0.6-0.7-1-1.4-1c-1.2,0-1.6,1-1.6,2.3\n		s0.4,2.3,1.6,2.3c0.7,0,1.2-0.4,1.4-1"/>\n</g>\n</svg>\n';

  // app/javascript/viewer/leaflet_viewer.js
  var import_leaflet = __toESM(require_leaflet_src());
  var LeafletViewer = class {
    constructor(figgyId, tabManager) {
      this.figgyId = figgyId;
      this.tabManager = tabManager;
      this.bindResize();
    }
    async loadLeaflet() {
      return this.checkTileJson().then(this.createLeaflet.bind(this)).then(() => this.bindTabs()).then(() => this.resize()).catch(() => {
      }).promise();
    }
    bindTabs() {
      this.tabManager.onTabSelect(() => this.focusMap());
    }
    bindResize() {
      window.addEventListener("resize", () => this.resize());
      this.resize();
    }
    resize() {
      if (this.map) {
        this.focusedMap = false;
        this.map.invalidateSize();
      }
    }
    focusMap() {
      if (this.map && !this.focusedMap) {
        this.focusedMap = true;
        this.map.invalidateSize();
        this.map.fitBounds([
          [this.tilejson.bounds[1], this.tilejson.bounds[0]],
          [this.tilejson.bounds[3], this.tilejson.bounds[2]]
        ]);
      }
    }
    createLeaflet(tilejson) {
      document.getElementById("tab-container").style.display = "block";
      document.getElementById("map-tab").style.display = "block";
      let map = import_leaflet.default.map("leaflet", {
        maxBounds: [[-100, -180], [100, 180]],
        touchZoom: false,
        scrollWheelZoom: false
      });
      import_leaflet.default.tileLayer("https://cartodb-basemaps-b.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png", {
        maxZoom: 18
      }).addTo(map);
      import_leaflet.default.tileLayer(tilejson.tiles[0], {
        maxZoom: 18
      }).addTo(map);
      this.map = map;
      this.tilejson = tilejson;
    }
    checkTileJson() {
      return $.ajax(this.tileJsonUrl, { type: "GET" });
    }
    get tileJsonUrl() {
      return `${this.tileMetadataRoot}/${this.figgyId}/tilejson`;
    }
    get mapTab() {
      return document.getElementById("map-tab-content");
    }
    get tileMetadataRoot() {
      return this.mapTab.getAttribute("data-tilemetadata");
    }
  };

  // app/javascript/viewer/tab_manager.js
  var TabManager = class {
    initialize() {
      this.bindTabs();
    }
    bindTabs() {
      this.onTabSelect(this.focusTab.bind(this));
    }
    onTabSelect(fn) {
      for (let i = 0; i < this.tabs.length; i++) {
        this.tabs[i].addEventListener("click", fn);
      }
    }
    focusTab(tabClickEvent) {
      for (let i = 0; i < this.tabs.length; i++) {
        this.tabs[i].classList.remove("active");
      }
      var clickedTab = tabClickEvent.currentTarget;
      clickedTab.classList.add("active");
      tabClickEvent.preventDefault();
      var ContentPanes = document.querySelectorAll(".tab-pane");
      for (let i = 0; i < ContentPanes.length; i++) {
        ContentPanes[i].classList.remove("active");
      }
      var anchorReference = tabClickEvent.target;
      var activePaneId = anchorReference.getAttribute("href");
      var activePane = document.querySelector(activePaneId);
      activePane.classList.add("active");
    }
    get tabs() {
      return document.querySelectorAll("ul.nav-tabs > li");
    }
  };

  // app/javascript/viewer/uv_manager.js
  var UVManager = class {
    async initialize() {
      this.bindLogin();
      this.bindResize();
      this.tabManager = new TabManager();
      this.tabManager.initialize();
      this.uvElement.hide();
      await this.loadUV();
      this.resize();
    }
    async loadUV() {
      return this.checkManifest().then(this.createUV.bind(this)).then(() => {
        return this.buildLeafletViewer();
      }).catch(this.requestAuth.bind(this)).promise();
    }
    buildLeafletViewer() {
      this.leafletViewer = new LeafletViewer(this.figgyId, this.tabManager);
      return this.leafletViewer.loadLeaflet();
    }
    checkManifest() {
      return $.ajax(this.manifest, { type: "HEAD" });
    }
    createUV(data, status, jqXHR) {
      this.tabManager.onTabSelect(() => setTimeout(() => this.resize(), 100));
      this.processTitle(jqXHR);
      this.uvElement.show();
      this.uv = createUV("#uv", {
        root: "uv",
        iiifResourceUri: this.manifest,
        configUri: this.configURI,
        collectionIndex: Number(this.urlDataProvider.get("c", 0)),
        manifestIndex: Number(this.urlDataProvider.get("m", 0)),
        sequenceIndex: Number(this.urlDataProvider.get("s", 0)),
        canvasIndex: Number(this.urlDataProvider.get("cv", 0)),
        rangeId: this.urlDataProvider.get("rid", 0),
        rotation: Number(this.urlDataProvider.get("r", 0)),
        xywh: this.urlDataProvider.get("xywh", ""),
        embedded: true
      }, this.urlDataProvider);
      this.cdlTimer = new CDLTimer(this.figgyId);
      this.cdlTimer.initializeTimer();
    }
    addViewerIcons() {
      const existingButton = document.querySelector("a.iiif-drag");
      const shareButton = document.querySelector(".footerPanel button.share");
      if (existingButton !== null || shareButton === null || shareButton.style.display === "none") {
        return;
      }
      const mobileShareButton = document.querySelector(".mobileFooterPanel button.share");
      shareButton.parentNode.insertBefore(this.createTakedownElement(), shareButton.nextSibling);
      mobileShareButton.parentNode.insertBefore(this.createTakedownElement(), mobileShareButton.nextSibling);
      shareButton.parentNode.insertBefore(this.createStatementElement(), shareButton.nextSibling);
      mobileShareButton.parentNode.insertBefore(this.createStatementElement(), mobileShareButton.nextSibling);
      shareButton.parentNode.insertBefore(this.createIIIFDragElement(), shareButton.nextSibling);
      mobileShareButton.parentNode.insertBefore(this.createIIIFDragElement(), mobileShareButton.nextSibling);
    }
    createIIIFDragElement() {
      const link = document.querySelector("a.imageBtn.iiif").href;
      const iconElement = document.createElement("a");
      iconElement.className = "btn imageBtn iiif-drag";
      iconElement.href = link;
      iconElement.target = "_blank";
      iconElement.innerHTML = `<img src="${iiif_logo_default}" style="width:25px; height=25px;"/>`;
      return iconElement;
    }
    createTakedownElement() {
      const iconElement = document.createElement("a");
      iconElement.className = "btn imageBtn takedown";
      iconElement.href = "https://library.princeton.edu/takedown-request";
      iconElement.target = "_blank";
      iconElement.innerHTML = `<img src="${copyright_default}" style="width:25px; height=25px;"/> <span id="takedown-rights">Rights and Permissions</span>`;
      return iconElement;
    }
    createStatementElement() {
      const iconElement = document.createElement("a");
      iconElement.className = "btn imageBtn statement";
      iconElement.href = "https://library.princeton.edu/statement-harmful-content";
      iconElement.target = "_blank";
      iconElement.innerHTML = `<img src="${statement_default}" style="width:25px; height=25px;"/> <span id="statement-on-harmful-content">Statement on Harmful Content</span>`;
      return iconElement;
    }
    waitForElementToDisplay(selector, time, callback) {
      if (document.querySelector(selector) != null) {
        callback();
      } else {
        setTimeout(function() {
          this.waitForElementToDisplay(selector, time, callback);
        }.bind(this), time);
      }
    }
    requestAuth(data, status) {
      if (data.status === 401) {
        if (this.manifest.includes(window.location.host)) {
          window.location.assign("/viewer/" + this.figgyId + "/auth");
        }
      }
    }
    get figgyId() {
      return this.manifest.replace("/manifest", "").replace(/.*\//, "");
    }
    get configURI() {
      return "/viewer/config/" + this.manifest.replace("/manifest", "").replace(/.*\//, "") + ".json";
    }
    processTitle(jqXHR) {
      var linkHeader = jqXHR.getResponseHeader("Link");
      if (linkHeader) {
        var titleMatch = /title="(.+?)"/.exec(linkHeader);
        if (titleMatch[1]) {
          var title = titleMatch[1];
          var titleElement = document.getElementById("title");
          titleElement.textContent = title;
          titleElement.style.display = "block";
          this.resize();
        }
      }
    }
    resize() {
      const windowWidth = window.innerWidth;
      const windowHeight = window.innerHeight;
      const titleHeight = $("#title").outerHeight($("#title").is(":visible"));
      let tabHeight = 0;
      if ($("#tab-container").is(":visible")) {
        tabHeight = $("#tab-container").outerHeight(true);
      }
      this.uvElement.width(windowWidth);
      this.uvElement.height(windowHeight - titleHeight - tabHeight);
      this.uvElement.children("div").height(windowHeight - titleHeight - tabHeight);
      if (this.uv) {
        this.uv.resize();
      }
      this.waitForElementToDisplay("button.share", 500, this.addViewerIcons.bind(this));
    }
    bindResize() {
      $(window).on("resize", () => this.resize());
      this.resize();
    }
    bindLogin() {
      $("#login").click(function(e) {
        e.preventDefault();
        var child = window.open("/users/auth/cas?login_popup=true");
        var timer = setInterval(checkChild, 200);
        function checkChild() {
          if (child.closed) {
            clearInterval(timer);
            window.location.reload();
          }
        }
      });
    }
    get urlDataProvider() {
      return new UV.URLDataProvider(false);
    }
    get manifest() {
      return this.urlDataProvider.get("manifest");
    }
    get uvElement() {
      return $("#uv");
    }
  };

  // app/javascript/viewer2.js
  var UVManagerInstance = new UVManager();
  window.addEventListener("uvLoaded", UVManagerInstance.initialize.bind(UVManagerInstance), false);
})();
/* @preserve
 * Leaflet 1.8.0, a JS library for interactive maps. https://leafletjs.com
 * (c) 2010-2022 Vladimir Agafonkin, (c) 2010-2011 CloudMade
 */
