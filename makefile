NODE_BIN      = node_modules/.bin
NPM           = npm
COFFEE        = $(NODE_BIN)/coffee
NYC           = $(NODE_BIN)/nyc
MOCHA         = $(NODE_BIN)/mocha
ISTANBUL      = $(NODE_BIN)/istanbul
COFFEELINT    = $(NODE_BIN)/coffeelint

FILES = ./decorators.coffee
TEST_FILES = `find ./test -name '*.coffee'`
COMPILED_TEST_FILES = `find ./test -name '*.js'`
MOCHA_OPTIONS = --compilers coffee:coffee-script/register --require ./coffee-decorators.js $(TEST_FILES)
MOCHA_CMD = $(MOCHA) $(MOCHA_OPTIONS)
MOCHA_DEBUG_CMD = $(MOCHA) --inspect-brk $(MOCHA_OPTIONS)

.PHONY: test


all: coffee

coffee:
	cat $(FILES) | $(COFFEE) --compile --stdio > ./coffee-decorators.js

test: all
	$(MOCHA_CMD)

coverage: all
	$(NYC) --reporter=html --reporter=text $(MOCHA_CMD)

lint:
	$(COFFEELINT) $(FILES) $(TEST_FILES)

debug-test: all
	$(MOCHA_DEBUG_CMD)
