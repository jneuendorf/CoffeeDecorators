# CoffeeDecorators
This library provides functions that can be used
like Python decorators or Java annotations respectively.

## Examples

### Abstract classes and methods

```coffee
# Class is attached to global scope.
# The local variable still points to the undecorated class
# so we need to update it.
Shape = @abstract class Shape
    @abstract \
    area: ->

class Rectangle extends Shape
    constructor: (@w, @h) ->
    area: ->
        return @w * @h

class Circle extends Shape
    constructor: (@r) ->

expect(-> new Shape).to.throw()
expect(-> new Rectangle).to.not.throw()
expect((new Rectangle(2, 3)).area()).to.equal(6)
expect(-> (new Circle(2)).area()).to.throw()
```
