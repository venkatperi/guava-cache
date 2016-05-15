should = require("should")
assert = require("assert")
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
Cache = require '../index'
ntimer = require 'ntimer'

describe "Cache", ->

  it "set expiry", ( done ) ->
    cache = new Cache expiry : '1m'
    cache.expiry().should.equal 1000 * 60
    done()

  it "insert item", ( done ) ->
    cache = new Cache()
    cache.set 'foo', 'bar'
    cache.get('foo').should.equal 'bar'
    done()

  it "emits 'set' on insert", ( done ) ->
    new Cache()
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .set 'foo', 'bar'

  it "global loader (function)", ( done ) ->
    loader = ( k ) -> 'bar'
    new Cache()
    .loader loader
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo').should.equal 'bar'

  it "global loader (object)", ( done ) ->
    loader =
      load : ( k ) -> 'bar'
    new Cache()
    .loader loader
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo').should.equal 'bar'

  it "local loader", ( done ) ->
    loader = -> 'bar'
    new Cache()
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo', loader).should.equal 'bar'

  it "evict by size", ( done ) ->
    evictionCount = 0
    cache = new Cache maxSize : 2
    .on 'delete', ( k, v, reason ) ->
      reason.should.equal 'size'
      k = Number k
      k.should.equal evictionCount++
      done() if k is 2
    cache.set i, i for i in [ 0..4 ]

  it "evict by time", ( done ) ->
    d = false
    cache = new Cache expiry : '3s'
    .on 'delete', ( k, v, reason ) ->
      reason.should.equal 'expiry'
      unless d
        done()
        d = true
    ntimer.autoRepeat 'insert', '1s', 10
    .on 'timer', ( n, i ) -> cache.set i, i

  it "stats - evict by size", ( done ) ->
    cache = new Cache expiry : '10s', maxSize : 3
    count = 100
    for i in [ 1..count ]
      cache.set i, i

    for i in [ 1..count*1000 ]
      cache.get Math.floor(Math.random() * count * 2)

    console.log cache.stats()
    done()

###
  it "stats - evict by time", ( done ) ->
    cache = new Cache expiry : '10s', maxSize : 3
    count = 100
    ntimer.autoRepeat 'set', 10, 8
    .on 'timer', ( n, i ) -> cache.set i, i
    .on 'done', ->
      ntimer.autoRepeat 'get', 10, 8
      .on 'timer', ( n, i ) ->
        cache.get i
      .on 'done', ->
        console.log cache.stats()
        done()

###
