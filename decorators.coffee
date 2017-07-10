# node.js
if typeof global is "object" and global?.global is global
    root = global
    exports = module.exports
# browser
else
    root = window
    exports = window



defineDecorator = (name, func) ->
    if root[name]?
        throw new Error("Can't define decorator because `root` already has a property with name '#{name}'.")
    root[name] = (args...) ->
        return func(args...)
    return root[name]

abstractDecorationHelper = (createErrorMessage) ->
    return (args...) ->
        if args.length is 2
            namespace = args[0]
            cls = args[1]
        else if args.length is 1
            namespace = @
            cls = args[0]

        if typeof(namespace) isnt "object" or typeof(cls) isnt "function"
            throw new Error("Invalid arguments. Expected (namespace, class) or (class).")

        name = cls.name
        # cls is also the old constructor
        decoratedClass = class Decorated extends cls
            constructor: () ->
                if @constructor is Decorated
                    throw new Error(createErrorMessage.call(@))
                # call actual constructor
                super

            # Wrapping the function results in the loss of properties -> we use this reference to reattach them
            origClass = Decorated
            # wrap the constructor and give it the `name`
            Decorated = wrapInNamedFunction(name, Decorated)
            # reattach __super__ and all other class attributes
            for own key, val of origClass
                Decorated[key] = val

        if namespace?
            namespace[name] = decoratedClass
        return decoratedClass

wrapInNamedFunction = (name, func) ->
    return eval("(function " + name + "(){return func.apply(this, arguments);})")


# helper function that converts given 1-elemtent dict (with any key) to {name, method}.
# the given dict is generated by using decorators/annotations like so:
#
# CoffeeScript:
#   @deprecated \
#   method: () ->
#
# JavaScript:
#   <CLASS_NAME>.deprecated({
#       method: function() {}
#   })
getStandardDict = (dict) ->
    result = {}
    for key, val of dict
        name = key
        method = val
    return {name, method}

# helper function to copy all properties in case of decorator chaining
copyMethodProps = (newMethod, oldMethod) ->
    for own key, val of oldMethod when not newMethod[key]?
        newMethod[key] = val
    return newMethod

# `callback` may return the new method or {method, parent}
# where method is the new method and parent is the object to attach the new method to.
methodHelper = (callback) ->
    return (dict) ->
        {name, method} = getStandardDict(dict)
        cls = @
        result = callback.call(cls, name, method, cls)
        isClassmethod = CoffeeDecorators.isClassmethod(method)
        # a potentially new (class) method has been returned -> attach it to the class or its prototype
        if typeof(result) is "function"
            method = result
            parent = if isClassmethod then cls else cls.prototype
        # provide `_super` as last argument for method because
        # CoffeeScript does not allow `super` in decorated methods:
        #   @decorator \
        #   method: -> super
        if isClassmethod
            superParent = cls.__super__.constructor
        else
            superParent = cls.__super__
        methodWithSuper = (args...) ->
            # need to define `_super` here to have the actual current `this`
            # One could assume `this == parent` but `this` could have been bound to something else with e.g. `call`.
            _super = () =>
                return superParent[name].apply(@, arguments)
            return method.apply(@, args.concat([_super]))
        methodWithSuper.__wrapped__ = method

        copyMethodProps(methodWithSuper, method)
        if parent?
            parent[name] = methodWithSuper
        dict[name] = methodWithSuper
        return dict

isClass = (obj) ->
    return obj.prototype?

# Get the class name of `this` - wether it's a class or an instance.
methodString = (obj, methodName) ->
    if isClass(obj)
        return "#{obj.name}.#{methodName}"
    return "#{obj.constructor.name}::#{methodName}"



Object.defineProperty exports, "pass", {
    get: () ->
        return undefined
    set: () ->
        return undefined
}

# These decorators only work for classes that are defined in the global namespace.
exports.abstract = defineDecorator "abstract", abstractDecorationHelper () ->
    return "Cannot instantiate abstract class '#{@constructor.name}'."

exports.interface = defineDecorator "interface", abstractDecorationHelper () ->
    return "Cannot instantiate interface '#{@constructor.name}'."



# DECORATORS FOR INSIDE CLASSES THAT EXTEND THE NATIVE OBJECT
# ALL ANNOTATIONS MUST RETURN THE GIVEN `dict` FOR ANNOTATION CHAINING
class CoffeeDecorators

    _console = console
    _allowOverrideDecorators = false

    # CONFIGURATION
    @setConsole: (console) ->
        _console = console
        return @

    @getConsole: () ->
        return _console

    @allowOverrideDecorators: () ->
        _allowOverrideDecorators = true

    @forbidOverrideDecorators: () ->
        _allowOverrideDecorators = false

    # INTROSPECTION
    @getWrappedMethod: (wrapper) ->
        wrapped = wrapper
        while wrapped.__wrapped__?
            wrapped = wrapped.__wrapped__
        return wrapped

    @isClassmethod: (method) ->
        return method.__classmethod__ is true

    @isDeprecated: (method) ->
        return method.__deprecated__ is true

    @isFinal: (method) ->
        return method.__final__ is true

    # DECORATORS
    @classmethod: methodHelper (name, method, cls) ->
        if name is "classmethod" and _allowOverrideDecorators is false
            throw new Error("You are using the '@classmethod' decorator on a method named 'classmethod'. This is not allowed unless you call 'CoffeeDecorators.allowOverrideDecorators()' first.")
        # Due to decorator chaining the method has previously been attached
        # to the prototype instead of the class itself
        # => remove it there so it only exists on the class.
        if cls::[name] is method
            delete cls::[name]
        method.__classmethod__ = true
        return method

    @deprecated: methodHelper (name, method) ->
        wrapper = () ->
            _console.warn("Call of #{methodString(@, name)} is deprecated.")
            return method.apply(@, arguments)
        wrapper.__deprecated__ = true
        return copyMethodProps(wrapper, method)

    @abstract: methodHelper (name, method) ->
        if not (/^function\s*\(.*?\)\s*\{\s*\}$/).test("#{@getWrappedMethod(method)}")
            throw new Error("Abstract methods must not have a function body.")

        cls = @
        wrapper = () ->
            if cls.isClassmethod(@[name])
                parent = cls
            else
                parent = cls.prototype
            # this check must contain dynamic lookup because the method could still be replaced by further decorators (-> wrappers)
            if @[name] is parent[name]
                throw new Error("#{methodString(parent, name)} must not be called because it is abstract.")
        return copyMethodProps(wrapper, method)

    @override: methodHelper (name, method, cls) ->
        # the prototype chain does not already contain the method
        # => it was not defined in a superclass
        # => method is NOT overridden
        isClassmethod = cls.isClassmethod(method)
        getParent = (prototype) ->
            if isClassmethod
                return prototype.constructor
            return prototype

        if not getParent(cls.prototype)[name]?
            throw new Error(
                "The method #{name} of type #{cls.name} must " +
                "override or implement a supertype method."
            )
        # look for final super methods
        superProto = cls.prototype
        while superProto.constructor.__super__?
            superProto = superProto.constructor.__super__
            parent = getParent(superProto)
            superMethod = parent[name]
            if superMethod? and CoffeeDecorators.isFinal(superMethod)
                throw new Error(
                    "#{methodString(cls, name)} must not override " +
                    "final method #{methodString(parent, name)}."
                )
        return method

    # only works if an accidentally overriding method uses `@override` or calls `super` or `_super`.
    @final: methodHelper (name, method, cls) ->
        wrapperMethod = () ->
            if @[name] isnt cls::[name]
                # `cls::getClassName()` is used insteaf of `cls.getName()` because heterarchy does not correctly support class method inheritance
                throw new Error("Method '#{cls::getClassName()}::#{name}' is final and must not be overridden (in '#{@getClassName()}')")
            return method.apply(@, arguments)
        wrapperMethod.__final__ = true
        return copyMethodProps(wrapperMethod, method)

    @cachedProperty: (dict) ->
        {name, method} = getStandardDict(dict)
        nullRef = {}
        cache = nullRef
        Object.defineProperty @::, name, {
            get: () ->
                if cache is nullRef
                    cache = method.call(@)
                return cache
            set: (value) ->
                cache = value
                return cache
        }
        return dict

    # Incrementally fills a dictionary of arguments-result pairs.
    # Arguments are compared using the argument's `equals` interface or with `===`.
    # The decorated method has a `clearCache()` method to reset the cache.
    @cached: (dict) ->
        # TODO: fix this: the cache is used across all different instances of a class (which results in really wrong behavior)
        throw new Error("Don't use @cached yet!")
        {name, method} = getStandardDict(dict)
        nullRef = {}
        # maps arguments to return value
        argListsEqual = (args1, args2) ->
            if args1.length isnt args2.length
                return false
            for args1Elem, i in args1
                args2Elem = args2[i]
                if args1Elem.equals?(args2Elem) is false or
                    args2Elem.equals?(args1Elem) is false or
                    args1Elem isnt args2Elem
                        return false
            return true
        createCache = () ->
            return new App.Hash(null, nullRef, argListsEqual)
        cache = createCache()
        wrapperMethod = (args...) ->
            value = cache.get(args)
            if value is nullRef
                value = method.apply(@, args)
                cache.put(args, value)
            return value
        wrapperMethod.clearCache = () ->
            cache = createCache()
        @::[name] = copyMethodProps(wrapperMethod, method)
        return dict

exports.CoffeeDecorators = CoffeeDecorators
