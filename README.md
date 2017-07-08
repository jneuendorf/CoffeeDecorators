# CoffeeDecorators
This library provides functions that can be used
like Python decorators or Java annotations respectively.
I personally found those really helpful during a big refactoring.
In the project we used multiple inheritance.
Therefore, it was really helpful to use the decorators to

- quickly figure out where a method occurs in the MRO,
- explicate intentions (e.g. marking methods as abstract) and
- marking methods as deprecated.

Due to CoffeeScript's syntax a `\` is required if the decorators are defined above the method itself.

```coffee
@decorator \
method: ->
# OR
@decorator method: ->
```

## Decorators

All decorators can be chained in any order.
For example the two are equal:

```coffee
@classmethod \
@deprecated \
classMethod: ->
    return someThing

@deprecated \
@classmethod \
classMethod: ->
    return someThing
```

### `@classmethod`

Because

```coffee
class A
    @decorator \
    @classMethod: ->
A.classMethod()
```

is invalid CoffeeScript the workaround to use decorators on classmethods
is to use the `@classmethod` decorator (like in Python).
So the example would then look like:

```coffee
class A
    @classmethod \
    @decorator \
    classMethod: ->
A.classMethod()
```

### `@deprecated`
### `@abstract`
### `@override`
### `@implements`
### `@final`
### `@cached`
### `@cachedProperty`

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
