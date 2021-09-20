'use strict';

const name = 'page-label-generator',
      version = '1.1.0';

const labelGen = {

  /**
   * Generator for page labels.
   *
   * A note about bracketing: Only one of `bracket`, `twoUpBracketLeftOnly`,
   * `twoUpBracketRightOnly` can be set, and `bracketEvens` and `bracketOdds`
   * can only be set if none of the first three options are set. The following
   * is an example of the difference between each option (this is also shown in
   * greater detail in the README).
   *
   * `bracket` wraps the whole string in brackets: [f. 1a], [f. 1b], [f 2a], ...
   *
   * `bracketEvens` and `bracketOdds` wraps just the evens/odds in brackets,
   *  and doesn't make much sense for twoUp configs: [p. 1], p. 2, [p. 3], ...
   *
   *  `twoUpBracketLeftOnly` and `twoUpBracketRightOnly` brackets just the
   * value on the right or left side of the separator: f. 2a/[1b], f. 3a/[2b],
   * f. 4a/[3b], ...
   *
   * @param {(number|string)} [start=1] - A number or a roman numeral.
   * @param {string} [method=paginate] - If set to "foliate" each value is
   * @param {string} [frontLabel=""]  - The label for the front of a leaf.
   * @param {string} [backLabel=""] - The label for the back of a leaf.
   *   yielded twice.
   * @param {string} [startWith=front] - If set to "back" and method=foliate,
   *   the first value only yielded once.
   * @param {string} [unitLabel=""] - A label for the unit, like "p. " or "f. ".
   * @param {boolean} [bracket=false] - If true add brackets ('[]') around the
   *   label.
   * @param {boolean} [bracketEvens=false] - If true add brackets ('[]') around
   *   the even numbered pages.
   * @param {boolean} [bracketOdds=false] - If true add brackets ('[]') around
   *   the odd numbered pages.
   * @param {boolean} [twoUp=false] - If true, yield two values as a time
   * @param {string} [twoUpSeparator="/"] - If twoUp, separate the values
   *   with this string.
   * @param {string} [twoUpDir="ltr"] - ltr or rtl. If twoUp and "rtl", the
   *   the larger value with be on the left of the separator
   * @param {string} [twoUpBracketLeftOnly=false] - If twoUp and true, bracket
   *   the value to the left of the separator only.
   * @param {string} [twoUpBracketRightOnly=false] - If twoUp and true, bracket
   *   the value to the right of the separator only.
   */
  pageLabelGenerator: function*({
    start = 1,
    method = 'paginate',
    frontLabel = '',
    backLabel = '',
    startWith ='front',
    unitLabel ='',
    bracket = false,
    bracketOdds = false,
    bracketEvens = false,
    twoUp  = false,
    twoUpSeparator = '/',
    twoUpDir = 'ltr',
    twoUpBracketLeftOnly=false,
    twoUpBracketRightOnly=false
  } = {}) {
    let numberer = this.pageNumberGenerator(arguments[0]),
        frontBackLabeler = this.frontBackLabeler(arguments[0]),
        bracketVals = this.bracketLogic(arguments[0]),
        [bracketOpen, bracketClose, bracketLeftOpen, bracketLeftClose,
          bracketRightOpen, bracketRightClose] = bracketVals,
        evenOddBracketsAllowed = bracketVals.every(v => v == ''),
        open = `${bracketOpen}${bracketLeftOpen}`,
        close = `${bracketRightClose}${bracketClose}`;
    while (true) {
      let [num1, c] = numberer.next().value,
          side1 = frontBackLabeler.next().value,
          page1 = `${num1}${side1}`,
          [eoBracketL, eoBracketR] = ['',''];
      if (evenOddBracketsAllowed) {
        [eoBracketL, eoBracketR] = this.evenOddBracket(c, bracketEvens, bracketOdds);
      }
      if (!twoUp) {
        yield `${open}${eoBracketL}${unitLabel}${page1}${eoBracketR}${close}`
      } else {
        let [num2, c] = numberer.next().value,
            side2 = frontBackLabeler.next().value,
            sep = `${bracketLeftClose}${twoUpSeparator}${bracketRightOpen}`,
            page2 = `${num2}${side2}`;
        if (twoUpDir=='rtl') {
          yield `${open}${unitLabel}${page2}${sep}${page1}${close}`;
        } else {
          yield `${open}${unitLabel}${page1}${sep}${page2}${close}`;
        }
      }
    }
  },

  evenOddBracket: function(numInt, doEvens, doOdds) {
    if ((doOdds && numInt % 2 == 1) || (doEvens && numInt % 2 == 0)) {
      return ['[', ']']
    } else {
      return ['', '']
    }

  },

  /**
   * Generator for page numbers.
   * @param {(number|string)} [start=1] - A number or a roman numeral.
   * @param {string} [method=paginate] - If set to "foliate" each value is
   *   yielded twice.
   * @param {string} [startWith=front] - If set to "back" and method=foliate,
   *   the first value only yielded once.
   * @yields {[(string, number]} - A two member array, the first item being
   *   the value for use in the label, and the second being that value
   *   represented as an integer.
   */
  pageNumberGenerator: function*({
    start = 1,
    method = 'paginate',
    startWith = 'front'
  } = {}) {
    let roman = false,
        capital = false,
        counter = start,
        changeFolio = false;

    if (!isInt(start)) {
      roman = true
      capital = start == start.toUpperCase()
      start.toLowerCase()
      counter = this.deromanize(start) // TODO: need an error if deromanize fails
    }

    if (startWith == 'back') changeFolio = !changeFolio

    while(true) {
      if (roman) {
        let val = this.romanize(counter);
        if (capital) val = val.toUpperCase()
        yield [val, counter];
      }
      else yield [String(counter), counter];

      if (method == 'foliate') {
        if (changeFolio) counter++;
        changeFolio = !changeFolio
      }
      else counter++
    }
  },

  /**
   * Generator for front and back of leaf labels.
   * @param {string} [frontLabel=""]  - The label for the front of a leaf.
   * @param {string} [backLabel=""] - The label for the back of a leaf.
   * @param {string} [startWith=front] - If set to "back", backLabel is yielded first.
   */
  frontBackLabeler: function*({
    frontLabel = '',
    backLabel = '',
    startWith = 'front'
  } = {}) {
    let labels = [ frontLabel, backLabel ];
    if (startWith == 'back') labels.reverse();
    let labeler = cycle(labels);
    while (true)
      yield labeler.next().value;
  },

  /**
   * Examine options to detemine what brackets to include. Only one of
   * `bracket`, `twoUpBracketLeftOnly`, `twoUpBracketRightOnly` can be set.
   * This function enforces that (interfaces should enforce it as well) and
   * returns the  appropriate strings for use in templates. If more than one
   * option is true, all brackets return will be empty strings (`''`).
   * @param {boolean} [bracket=false] - If true add brackets ('[]') around the
   *   entire label.
   * @param {string} [twoUpBracketLeftOnly=false] - If twoUp and true, bracket
   *   the value to the left of the separator only.
   * @param {string} [twoUpBracketRightOnly=false] - If twoUp and true, bracket
   *   the value to the right of the separator only.
   */
  bracketLogic: function({
    bracket = false,
    twoUpBracketLeftOnly = false,
    twoUpBracketRightOnly = false
  } = {}) {
    var bracketOpen = '',
        bracketClose = '',
        bracketLeftOpen = '',
        bracketLeftClose = '',
        bracketRightOpen = '',
        bracketRightClose = ''
    if (bracket && !(twoUpBracketLeftOnly || twoUpBracketRightOnly)) {
      [bracketOpen, bracketClose] = ['[',']']
    } else if (twoUpBracketLeftOnly &&  !(bracket || twoUpBracketRightOnly)) {
      [bracketLeftOpen, bracketLeftClose] = ['[',']']
    } else if (twoUpBracketRightOnly &&  !(bracket || twoUpBracketLeftOnly)) {
      [bracketRightOpen, bracketRightClose] = ['[',']']
    }
    return [bracketOpen, bracketClose, bracketLeftOpen, bracketLeftClose,
      bracketRightOpen, bracketRightClose]
  },

  /**
   * Roman numeral helpers lifted from
   * http://blog.stevenlevithan.com/archives/javascript-roman-numeral-converter
   * with only slight modifications
   */
  romanize: function(num) {
    if (!+num)
      return false;
    var  digits = String(+num).split(''),
      key = ['','c','cc','ccc','cd','d','dc','dcc','dccc','cm',
             '','x','xx','xxx','xl','l','lx','lxx','lxxx','xc',
             '','i','ii','iii','iv','v','vi','vii','viii','ix'],
      roman = '',
      i = 3;
    while (i--)
      roman = (key[+digits.pop() + (i * 10)] || '') + roman;
    return Array(+digits.join('') + 1).join('m') + roman;
  },

  /**
   * Roman numeral helpers lifted from
   * http://blog.stevenlevithan.com/archives/javascript-roman-numeral-converter
   * with only slight modifications
   */
  deromanize: function(str) {
    str = str.toLowerCase()
    var validator = /^m*(?:d?c{0,3}|c[md])(?:l?x{0,3}|x[cl])(?:v?i{0,3}|i[xv])$/,
        token = /[mdlv]|c[md]?|x[cl]?|i[xv]?/g,
        key = {m:1000,cm:900,d:500,cd:400,c:100,xc:90,l:50,xl:40,x:10,ix:9,v:5,iv:4,i:1},
        num = 0, m;
    if (!(str && validator.test(str)))
      return false;
    // eslint-disable-next-line no-cond-assign
    while (m = token.exec(str))
      num += key[m[0]];
    return num;
  }
}

/**
 * Generator to endlessly iterate through the members of an array, starting over
 * at the beginning when members run out.
 * @param {*[]} arr - An array of anything.
 */
function* cycle(arr) {
  while (true) {
    let nxt = arr.shift();
    arr.push(nxt);
    yield nxt;
  }
}

function isInt(n){
  return Number(n) === n && n % 1 === 0;
}

export default labelGen;
