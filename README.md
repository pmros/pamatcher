#Pamatcher

## What is Pamatcher?
Pamatcher is a pattern matching library for Javascript. It's like regular expressions but more general. Instead strings, you can use any iterable or iterator as input. Instead of characters you can use any predicate as item matcher. So you can do pattern matching in a general and declarative way.

## How can I use Pamatcher?
You can download Pamatcher using npm. This is an example:

```
var pm = require('pamatcher');

matcher = pm.Pamatcher(
  function(i) { return i < 10 },
  pm.repeat( function(i) { return i%2==0 } ),
  function(i) { return i > 10 }
);

result = matcher.test([1, 4, 8, 44, 55]);
if(result)
  console.log("Pattern matches!");
else
  console.log("Pattern doesn't match.");
```

In the example, the pattern is simple: match a number lesser than 10, followed by zero o more odd numbers and finally a number greater than 10. You test an array and it should print "Pattern matches!". See tests for more examples.

That code could be a little noisy, it's better coded in Javascript ES6 syntax or even better with LiveScript:
```livescript
matcher = pm.Pamatcher do
  (< 10)
  pm.repeat -> it%2 is 0
  (> 10)

```

## TODO
- Browser suport.
- Patterns as JSON like expressions.
- Cardinality for repeat pattern.
- Better documentation.
- More tests.
