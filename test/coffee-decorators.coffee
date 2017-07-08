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


useCustomConsole = () ->
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
            useCustomConsole()

        after ->
            CoffeeDecorators.setConsole(console)


        it "deprecated", ->
            class A extends CoffeeDecorators
                @deprecated \
                method: () ->
                    return 2

            a = new A()
            # expect(CoffeeDecorators.isDeprecated(a.method))
            result = a.method()
            expect(result).to.equal(2)
            expect(CoffeeDecorators.getConsole().warned.last())
                .to.equal("Call of A::method is deprecated.")

        it "override", ->
            expect(() ->
                class A extends CoffeeDecorators
                    @override \
                    method: () ->
            ).to.throw()

            class A extends CoffeeDecorators
                method: () ->
                    return 1

            class B extends A
                @override \
                method: (_super) ->
                    return _super() + 1

            # implicit: class creation worked
            expect((new B()).method()).to.equal(2)


    describe "class methods", ->

        before ->
            useCustomConsole()

        after ->
            CoffeeDecorators.setConsole(console)


        it "classmethod", ->
            class B extends CoffeeDecorators
                @classmethod \
                classMethod: () ->
                    return 2
            expect(B.classMethod).to.be.a("function")
            expect(B.classMethod()).to.equal(2)

        it "deprecated", ->
            class B extends CoffeeDecorators
                @deprecated @classmethod \
                classMethod1: () ->
                    return 1

                @classmethod @deprecated \
                classMethod2: () ->
                    return 2

            result = B.classMethod1()
            expect(result).to.equal(1)
            expect(CoffeeDecorators.getConsole().warned.last())
                .to.equal("Call of B.classMethod1 is deprecated.")
            result = B.classMethod2()
            expect(result).to.equal(2)
            expect(CoffeeDecorators.getConsole().warned.last())
                .to.equal("Call of B.classMethod2 is deprecated.")

    describe "introspection", ->

        it "isClassmethod", ->
        it "isDeprecated", ->
        it "isFinal", ->
