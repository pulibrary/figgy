"use strict"

let exports = {}

Object.defineProperty(exports, "__esModule", {
  value: true,
})

var _slicedToArray = (function() {
  function sliceIterator(arr, i) {
    var _arr = []
    var _n = true
    var _d = false
    var _e = undefined
    try {
      for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
        _arr.push(_s.value)
        if (i && _arr.length === i) break
      }
    } catch (err) {
      _d = true
      _e = err
    } finally {
      try {
        if (!_n && _i["return"]) _i["return"]()
      } finally {
        if (_d) throw _e
      }
    }
    return _arr
  }
  return function(arr, i) {
    if (Array.isArray(arr)) {
      return arr
    } else if (Symbol.iterator in Object(arr)) {
      return sliceIterator(arr, i)
    } else {
      throw new TypeError("Invalid attempt to destructure non-iterable instance")
    }
  }
})()

var _marked = /*#__PURE__*/ regeneratorRuntime.mark(cycle)

var name = "page-label-generator",
  version = "1.0.3"

var labelGen = {
  name: name,
  version: version,
  pageLabelGenerator: /*#__PURE__*/ regeneratorRuntime.mark(function pageLabelGenerator() {
    var opts =
      arguments.length > 0 && arguments[0] !== undefined
        ? arguments[0]
        : {
            start: 1,
            method: "paginate",
            frontLabel: "",
            backLabel: "",
            startWith: "front",
            unitLabel: "",
            bracket: false,
          }

    var numberer, frontBackLabeler, _ref, _ref2, bracketOpen, bracketClose, num, side

    return regeneratorRuntime.wrap(
      function pageLabelGenerator$(_context) {
        while (1) {
          switch ((_context.prev = _context.next)) {
            case 0:
              ;(numberer = this.pageNumberGenerator(opts)),
                (frontBackLabeler = this.frontBackLabeler(opts)),
                (_ref = opts.bracket ? ["[", "]"] : ["", ""]),
                (_ref2 = _slicedToArray(_ref, 2)),
                (bracketOpen = _ref2[0]),
                (bracketClose = _ref2[1])

            case 1:
              if (!true) {
                _context.next = 7
                break
              }

              ;(num = numberer.next().value), (side = frontBackLabeler.next().value)
              _context.next = 5
              return ("" + bracketOpen + opts.unitLabel + num + side + bracketClose).trim()

            case 5:
              _context.next = 1
              break

            case 7:
            case "end":
              return _context.stop()
          }
        }
      },
      pageLabelGenerator,
      this
    )
  }),

  pageNumberGenerator: /*#__PURE__*/ regeneratorRuntime.mark(function pageNumberGenerator() {
    var opts =
      arguments.length > 0 && arguments[0] !== undefined
        ? arguments[0]
        : {
            start: 1,
            method: "paginate",
            startWith: "front",
          }
    var roman, capital, counter, changeFolio, val
    return regeneratorRuntime.wrap(
      function pageNumberGenerator$(_context2) {
        while (1) {
          switch ((_context2.prev = _context2.next)) {
            case 0:
              ;(roman = false), (capital = false), (counter = opts.start), (changeFolio = false)

              if (!isInt(opts.start)) {
                roman = true
                capital = opts.start == opts.start.toUpperCase()
                opts.start.toLowerCase()
                counter = this.deromanize(opts.start) // TODO: need an error if deromanize fails
              }

              if (opts.startWith == "back") changeFolio = !changeFolio

            case 3:
              if (!true) {
                _context2.next = 16
                break
              }

              if (!roman) {
                _context2.next = 11
                break
              }

              val = this.romanize(counter)

              if (capital) val = val.toUpperCase()
              _context2.next = 9
              return val

            case 9:
              _context2.next = 13
              break

            case 11:
              _context2.next = 13
              return counter

            case 13:
              if (opts.method == "foliate") {
                if (changeFolio) counter++
                changeFolio = !changeFolio
              } else counter++
              _context2.next = 3
              break

            case 16:
            case "end":
              return _context2.stop()
          }
        }
      },
      pageNumberGenerator,
      this
    )
  }),

  frontBackLabeler: /*#__PURE__*/ regeneratorRuntime.mark(function frontBackLabeler() {
    var opts =
      arguments.length > 0 && arguments[0] !== undefined
        ? arguments[0]
        : {
            frontLabel: "",
            backLabel: "",
            startWith: "front",
          }
    var labels, labeler
    return regeneratorRuntime.wrap(
      function frontBackLabeler$(_context3) {
        while (1) {
          switch ((_context3.prev = _context3.next)) {
            case 0:
              labels = [opts.frontLabel, opts.backLabel]

              if (opts.startWith == "back") labels.reverse()
              labeler = cycle(labels)

            case 3:
              if (!true) {
                _context3.next = 8
                break
              }

              _context3.next = 6
              return labeler.next().value

            case 6:
              _context3.next = 3
              break

            case 8:
            case "end":
              return _context3.stop()
          }
        }
      },
      frontBackLabeler,
      this
    )
  }),

  romanize: function romanize(num) {
    if (!+num) return false
    var digits = String(+num).split(""),
      key = [
        "",
        "c",
        "cc",
        "ccc",
        "cd",
        "d",
        "dc",
        "dcc",
        "dccc",
        "cm",
        "",
        "x",
        "xx",
        "xxx",
        "xl",
        "l",
        "lx",
        "lxx",
        "lxxx",
        "xc",
        "",
        "i",
        "ii",
        "iii",
        "iv",
        "v",
        "vi",
        "vii",
        "viii",
        "ix",
      ],
      roman = "",
      i = 3
    while (i--) {
      roman = (key[+digits.pop() + i * 10] || "") + roman
    }
    return Array(+digits.join("") + 1).join("m") + roman
  },

  deromanize: function deromanize(str) {
    var str = str.toLowerCase(),
      validator = /^m*(?:d?c{0,3}|c[md])(?:l?x{0,3}|x[cl])(?:v?i{0,3}|i[xv])$/,
      token = /[mdlv]|c[md]?|x[cl]?|i[xv]?/g,
      key = { m: 1000, cm: 900, d: 500, cd: 400, c: 100, xc: 90, l: 50, xl: 40, x: 10, ix: 9, v: 5, iv: 4, i: 1 },
      num = 0,
      m
    if (!(str && validator.test(str))) return false
    while ((m = token.exec(str))) {
      num += key[m[0]]
    }
    return num
  },
}
function cycle(arr) {
  var nxt
  return regeneratorRuntime.wrap(
    function cycle$(_context4) {
      while (1) {
        switch ((_context4.prev = _context4.next)) {
          case 0:
            if (!true) {
              _context4.next = 7
              break
            }

            nxt = arr.shift()

            arr.push(nxt)
            _context4.next = 5
            return nxt

          case 5:
            _context4.next = 0
            break

          case 7:
          case "end":
            return _context4.stop()
        }
      }
    },
    _marked,
    this
  )
}

function isInt(n) {
  return Number(n) === n && n % 1 === 0
}

exports.default = labelGen
