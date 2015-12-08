# pamatcher 

[![npm version](https://badge.fury.io/js/pamatcher.svg)](http://badge.fury.io/js/pamatcher)
[![Build Status](https://travis-ci.org/pmros/pamatcher.svg)](https://travis-ci.org/pmros/pamatcher)

A pattern matching library for JavaScript iterators.

**pamatcher** is a JavaScript library that generalizes the notion of regular expressions to any sequence of items of any type. Instead strings, you can use any iterable or iterator as input. Instead of characters you can use any predicate as item matcher. So you can do pattern matching in a general and declarative way.

## Installation and usage
You can install pamatcher using npm:
```bash
npm install pamatcher
```

This is an example of use:

```js
var pamatcher = require('pamatcher');

var matcher = pamatcher(
  (i) => i < 10,
  { repeat: (i) => i%2==0 },
  (i) => i > 10
);

var result = matcher.test([1, 4, 8, 44, 55]);
if(result) {
  console.log("Pattern matches!");
} else {
  console.log("Pattern doesn't match.");
}
```

In the example, the pattern is simple: match a number lesser than 10, followed by zero or more even numbers and finally a number greater than 10. You test an array and it should print "Pattern matches!". See tests for more examples.

If you want to use pamatcher from browser, you can use [jspm](http://jspm.io/). Here you have a complete pamatcher demo for browser at [gist](https://gist.github.com/pmros/137ecf2351e0f2fe44d4) (or live at [bl.ocks.org](http://bl.ocks.org/pmros/137ecf2351e0f2fe44d4)). You can play online with pamatcher via [jsfiddle](https://jsfiddle.net/8f4mcoq5/).

## API

### pamatcher(expression)

This is a function that transforms a pattern expression into a [matcher](#matcher-object). This is the only thing you need to import/require to use pamatcher library.

A pattern expression is a JavaScript object that specify the pattern you want to use. A pattern expression can be:

#### [function]
A predicate, that is a function that takes an input item, evaluates it and return a boolean. True means "item accepted".

#### { value: [whatever] }
This is a shortcut for a (deep) equality predicate.

#### { sequence: [array of expressions] }
A sequence of expressions.
It's something like this regex:  /abc/
Usually pamatcher can convert arrays of expressions to a sequence expression for a better readability. Also pamatcher function can automatically convert any number of arguments to a sequence expression (see example above).

#### { or: [array of expressions] }
Logical or of multiple expressions.
It's something like this regex:  /(a|b|c)/

#### { optional: [expression] }
An optional expression.
It's something like this regex:  /a?/

#### { repeat: [expression] }
A sequence of zero or more expressions repeated.
It's something like this regex:  /a*/

#### { repeat: [expression], min: [int], max: [int] }
A sequence from two up to five expressions repeated.
It's something like this regex: /a{2,5}/

### matcher object
A matcher object can check if your expression matches to an input.

#### matcher.test(input)
The input is an iterator or an iterable. These are ES6 features. Array, String, Map, Set are iterables.

test method returns true if your pattern expression matchs your input, otherwise it returns false.


## TODO
- [x] Pattern expressions.
- [x] Browser suport.
- [x] Cardinality for repeat pattern.
- [ ] Simple expressions using strings like traditional regular expressions.
- [ ] Error handling.
- [ ] Capturing groups.
- [ ] More information avaible for predicates (index, previous item...).
