path = require('path')
coffeeCoverage = require('coffee-coverage')
projectRoot = __dirname
coverageVar = coffeeCoverage.findIstanbulVariable()

# Only write a coverage report if we're not running inside of Istanbul.
unless coverageVar
  writeOnExit = "#{projectRoot}/coverage/coverage-coffee.json"

coffeeCoverage.register
  instrumentor : 'istanbul'
  basePath : projectRoot
  exclude : [
    '/test'
    '/node_modules'
    '/.git'
    '/Gruntfile.coffee'
    '/coffee-coverage-loader.coffee'
  ]
  coverageVar : coverageVar
  writeOnExit : writeOnExit
  initAll : true
