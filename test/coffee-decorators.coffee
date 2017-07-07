# node.js
if typeof global is "object" and global?.global is global
    root = global
    chai = require("chai")
    coffee_decorators = require("../coffee-decorators")
# browser
else
    root = window
    chai = window.chai
    coffee_decorators = window.coffee_decorators

{expect} = chai
should = do chai.should


describe "coffee-decorators", ->

    it "abstract", () ->
        namespace = {}
        # let's pretend we're in the global scope
        (() ->
            # This assignment is only necessary to update the local variable
            # created by CoffeeScript.
            # Since `AbstractClass` will be attached to the global namespace
            # it is NOT necessary if used in a different scope.
            AbstractClass = @abstract class AbstractClass
                constructor: () ->
                    @prop = 2
            expect(() -> new AbstractClass()).to.throw()

            @abstract namespace, class AbstractClass
                constructor: () ->
                    @prop = 2
            expect(() -> new namespace.AbstractClass()).to.throw()
        ).call(root)

        expect(AbstractClass).to.not.equal(namespace.AbstractClass)
        expect(() -> new AbstractClass()).to.throw()
        class A extends AbstractClass
        expect(() -> new A()).to.not.throw()
        class B extends namespace.AbstractClass
        expect(() -> new B()).to.not.throw()
