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

  it "get with loader", ( done ) ->
    loader = ( k ) -> 'bar'
    new Cache()
    .loader loader
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo').should.equal 'bar'

  it "get with property loader", ( done ) ->
    loader = -> 'bar'
    new Cache()
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo', loader).should.equal 'bar'

  it "evict by size", ( done ) ->
    evictionCount = 0
    cache = new Cache maxSize : 2, timer : '1s'
    .on 'delete', ( k, reason ) ->
      reason.should.equal 'maximum size exceeded'
      k = Number k
      k.should.equal evictionCount++
      done() if k is 2
    cache.set i, i for i in [ 0..4 ]

  it "evict by time", ( done ) ->
    cache = new Cache expiry : '3s', timer : '1s'
    .on 'delete', ( k, reason ) ->
      reason.should.equal 'expired'
      k.should.equal 'foo'
      done()
    .set 'foo', 'bar'

  it "stats", ( done ) ->
    cache = new Cache expiry : '10s', timer : 500, maxSize : 3
    ntimer.autoRepeat 'set', '1s', 4
    .on 'timer', ( n, i ) -> cache.set i, i
    .on 'done', ->
      ntimer.autoRepeat 'get', '1s', 4
      .on 'timer', ( n, i ) ->
        cache.get Math.floor(Math.random() * 16)
      .on 'done', ->
        console.log cache.stats()
        done()
      

