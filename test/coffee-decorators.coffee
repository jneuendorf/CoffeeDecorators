# node.js
if typeof global is "object" and global?.global is global
    root = global
    chai = require("chai")
    CoffeeDecorators = require("../coffee-decorators").CoffeeDecorators
# browser
else
    root = window
    chai = window.chai
    CoffeeDecorators = window.CoffeeDecorators

{expect} = chai
should = do chai.should


describe "coffee-decorators", ->

    describe "classes", ->

        it "abstract", ->
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

            # invalid arguments
            expect(() -> @abstract()).to.throw()
            expect(() -> @abstract(1, AbstractClass)).to.throw()
            expect(() -> @abstract(namespace, AbstractClass, 3)).to.throw()
            # check class creation
            expect(AbstractClass).to.not.equal(namespace.AbstractClass)

            expect(() -> new AbstractClass()).to.throw()
            class A extends AbstractClass
            expect(() -> new A()).to.not.throw()
            class B extends namespace.AbstractClass
            expect(() -> new B()).to.not.throw()


    describe "methods", ->

        before ->
            class Console
                constructor: () ->
                    @logged = []
                    @warned = []
                    @errors = []

                log: (args...) ->
                    @logged.push(args.join(" "))
                    return @

                warn: (args...) ->
                    @warned.push(args.join(" "))
                    return @

                error: (args...) ->
                    @errors.push(args.join(" "))
                    return @
            CoffeeDecorators.setConsole(new Console())
            Array::last = () ->
                return @slice(-1)[0]

        after ->
            CoffeeDecorators.setConsole(console)


        it "deprecated", ->
            # must inherit from CoffeeDecorators
            expect(
                () -> class A
                    @deprecated \
                    method: () ->
                        return 2
            ).to.throw()

            class B extends CoffeeDecorators
                @deprecated \
                method: () ->
                    return 2

            b = new B()
            expect(CoffeeDecorators.isDeprecated(b.method))
            result = b.method()
            expect(result).to.equal(2)
            expect(CoffeeDecorators.getConsole().warned.last()).to.equal("Call of B::method is deprecated.")

    describe "class methods", ->
        it "classmethod", ->
            class B extends CoffeeDecorators
                @classmethod \
                classmethod: () ->
                    return 2
            expect(B.classmethod).to.be.a("function")
            expect(B.classmethod()).to.equal(2)

        it "deprecated", ->
            class B extends CoffeeDecorators
                @deprecated @classmethod \
                classmethod: () ->
                    return 2

            expect(CoffeeDecorators.isDeprecated(B.classmethod))
            result = B.classmethod()
            expect(result).to.equal(2)
            expect(CoffeeDecorators.getConsole().warned.last()).to.eql([
                "Call of B.classmethod is deprecated."
            ])
