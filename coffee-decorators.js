// Generated by CoffeeScript 1.12.6
(function() {
  var CoffeeDecorators, abstractDecorationHelper, copyMethodProps, defineDecorator, exports, getStandardDict, hashIt, isClass, methodHelper, methodString, root, wrapInNamedFunction,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  if (typeof global === "object" && (typeof global !== "undefined" && global !== null ? global.global : void 0) === global) {
    root = global;
    exports = module.exports;
    hashIt = require("hash-it");
  } else {
    root = window;
    exports = window;
    hashIt = window.hashIt;
  }

  defineDecorator = function(name, func) {
    if (root[name] != null) {
      throw new Error("Can't define decorator because `root` already has a property with name '" + name + "'.");
    }
    root[name] = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return func.apply(null, args);
    };
    return root[name];
  };

  abstractDecorationHelper = function(createErrorMessage) {
    return function() {
      var Decorated, args, cls, decoratedClass, name, namespace;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (args.length === 2) {
        namespace = args[0];
        cls = args[1];
      } else if (args.length === 1) {
        namespace = this;
        cls = args[0];
      }
      if (typeof namespace !== "object" || typeof cls !== "function") {
        throw new Error("Invalid arguments. Expected (namespace, class) or (class).");
      }
      name = cls.name;
      decoratedClass = Decorated = (function(superClass) {
        var key, origClass, val;

        extend(Decorated, superClass);

        function Decorated() {
          if (this.constructor === Decorated) {
            throw new Error(createErrorMessage.call(this));
          }
          Decorated.__super__.constructor.apply(this, arguments);
        }

        origClass = Decorated;

        Decorated = wrapInNamedFunction(name, Decorated);

        for (key in origClass) {
          if (!hasProp.call(origClass, key)) continue;
          val = origClass[key];
          Decorated[key] = val;
        }

        return Decorated;

      })(cls);
      if (namespace != null) {
        namespace[name] = decoratedClass;
      }
      return decoratedClass;
    };
  };

  wrapInNamedFunction = function(name, func) {
    return eval("(function " + name + "(){return func.apply(this, arguments);})");
  };

  getStandardDict = function(dict) {
    var key, method, name, result, val;
    result = {};
    for (key in dict) {
      val = dict[key];
      name = key;
      method = val;
    }
    return {
      name: name,
      method: method
    };
  };

  copyMethodProps = function(newMethod, oldMethod) {
    var key, val;
    for (key in oldMethod) {
      if (!hasProp.call(oldMethod, key)) continue;
      val = oldMethod[key];
      if (newMethod[key] == null) {
        newMethod[key] = val;
      }
    }
    return newMethod;
  };

  methodHelper = function(callback) {
    return function(dict) {
      var cls, isClassmethod, method, methodWithSuper, name, parent, ref, result, superParent;
      ref = getStandardDict(dict), name = ref.name, method = ref.method;
      cls = this;
      result = callback.call(cls, name, method, cls);
      isClassmethod = CoffeeDecorators.isClassmethod(method);
      if (typeof result === "function") {
        method = result;
        parent = isClassmethod ? cls : cls.prototype;
      }
      if (isClassmethod) {
        superParent = cls.__super__.constructor;
      } else {
        superParent = cls.__super__;
      }
      methodWithSuper = function() {
        var _super, args;
        args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        _super = (function(_this) {
          return function() {
            return superParent[name].apply(_this, arguments);
          };
        })(this);
        return method.apply(this, args.concat([_super]));
      };
      methodWithSuper.__wrapped__ = method;
      copyMethodProps(methodWithSuper, method);
      if (parent != null) {
        parent[name] = methodWithSuper;
      }
      dict[name] = methodWithSuper;
      return dict;
    };
  };

  isClass = function(obj) {
    return obj.prototype != null;
  };

  methodString = function(obj, methodName) {
    if (isClass(obj)) {
      return obj.name + "." + methodName;
    }
    return obj.constructor.name + "::" + methodName;
  };

  Object.defineProperty(exports, "pass", {
    get: function() {
      return void 0;
    },
    set: function() {
      return void 0;
    }
  });

  exports.abstract = defineDecorator("abstract", abstractDecorationHelper(function() {
    return "Cannot instantiate abstract class '" + this.constructor.name + "'.";
  }));

  exports["interface"] = defineDecorator("interface", abstractDecorationHelper(function() {
    return "Cannot instantiate interface '" + this.constructor.name + "'.";
  }));

  CoffeeDecorators = (function() {
    var _allowOverrideDecorators, _console;

    function CoffeeDecorators() {}

    _console = console;

    _allowOverrideDecorators = false;

    CoffeeDecorators.setConsole = function(console) {
      _console = console;
      return this;
    };

    CoffeeDecorators.getConsole = function() {
      return _console;
    };

    CoffeeDecorators.allowOverrideDecorators = function() {
      return _allowOverrideDecorators = true;
    };

    CoffeeDecorators.forbidOverrideDecorators = function() {
      return _allowOverrideDecorators = false;
    };

    CoffeeDecorators.getWrappedMethod = function(wrapper) {
      var wrapped;
      wrapped = wrapper;
      while (wrapped.__wrapped__ != null) {
        wrapped = wrapped.__wrapped__;
      }
      return wrapped;
    };

    CoffeeDecorators.isClassmethod = function(method) {
      return method.__classmethod__ === true;
    };

    CoffeeDecorators.isDeprecated = function(method) {
      return method.__deprecated__ === true;
    };

    CoffeeDecorators.isFinal = function(method) {
      return method.__final__ === true;
    };

    CoffeeDecorators.classmethod = methodHelper(function(name, method, cls) {
      if (name === "classmethod" && _allowOverrideDecorators === false) {
        throw new Error("You are using the '@classmethod' decorator on a method named 'classmethod'. This is not allowed unless you call 'CoffeeDecorators.allowOverrideDecorators()' first.");
      }
      if (cls.prototype[name] === method) {
        delete cls.prototype[name];
      }
      method.__classmethod__ = true;
      return method;
    });

    CoffeeDecorators.deprecated = methodHelper(function(name, method) {
      var wrapper;
      wrapper = function() {
        _console.warn("Call of " + (methodString(this, name)) + " is deprecated.");
        return method.apply(this, arguments);
      };
      wrapper.__deprecated__ = true;
      return copyMethodProps(wrapper, method);
    });

    CoffeeDecorators.abstract = methodHelper(function(name, method) {
      var cls, wrapper;
      if (!/^function\s*\(.*?\)\s*\{\s*\}$/.test("" + (this.getWrappedMethod(method)))) {
        throw new Error("Abstract methods must not have a function body.");
      }
      cls = this;
      wrapper = function() {
        var parent;
        if (cls.isClassmethod(this[name])) {
          parent = cls;
        } else {
          parent = cls.prototype;
        }
        if (this[name] === parent[name]) {
          throw new Error((methodString(parent, name)) + " must not be called because it is abstract.");
        }
      };
      return copyMethodProps(wrapper, method);
    });

    CoffeeDecorators.override = methodHelper(function(name, method, cls) {
      var getParent, isClassmethod, parent, superMethod, superProto;
      isClassmethod = cls.isClassmethod(method);
      getParent = function(prototype) {
        if (isClassmethod) {
          return prototype.constructor;
        }
        return prototype;
      };
      if (getParent(cls.prototype)[name] == null) {
        throw new Error(("The method " + name + " of type " + cls.name + " must ") + "override or implement a supertype method.");
      }
      superProto = cls.prototype;
      while (superProto.constructor.__super__ != null) {
        superProto = superProto.constructor.__super__;
        parent = getParent(superProto);
        superMethod = parent[name];
        if ((superMethod != null) && CoffeeDecorators.isFinal(superMethod)) {
          throw new Error(((methodString(cls, name)) + " must not override ") + ("final method " + (methodString(parent, name)) + "."));
        }
      }
      return method;
    });

    CoffeeDecorators.final = methodHelper(function(name, method, cls) {
      var parent, wrapperMethod;
      if (CoffeeDecorators.isClassmethod(method)) {
        parent = cls;
      } else {
        parent = cls.prototype;
      }
      wrapperMethod = function() {
        if (this !== parent) {
          throw new Error((methodString(parent, name)) + " must is final and must not be overridden.");
        }
        return method.apply(this, arguments);
      };
      wrapperMethod.__final__ = true;
      return copyMethodProps(wrapperMethod, method);
    });

    CoffeeDecorators.cachedProperty = function(dict) {
      var cache, method, name, nullRef, ref;
      ref = getStandardDict(dict), name = ref.name, method = ref.method;
      nullRef = {};
      cache = nullRef;
      Object.defineProperty(this.prototype, name, {
        get: function() {
          if (cache === nullRef) {
            cache = method.call(this);
          }
          return cache;
        },
        set: function(value) {
          cache = value;
          return cache;
        }
      });
      return dict;
    };

    CoffeeDecorators.cached = methodHelper(function(name, method, cls) {
      var cache, wrapper;
      cache = {};
      wrapper = function() {
        var args, argsHash, thisCache, thisHash;
        args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        thisHash = hashIt(this);
        if (!cache.hasOwnProperty(thisHash)) {
          cache[thisHash] = {};
        }
        thisCache = cache[thisHash];
        argsHash = hashIt(args);
        if (!thisCache.hasOwnProperty(argsHash)) {
          thisCache[argsHash] = method.apply(this, args);
        }
        return thisCache[argsHash];
      };
      return wrapper;
    });

    return CoffeeDecorators;

  })();

  exports.CoffeeDecorators = CoffeeDecorators;

}).call(this);
