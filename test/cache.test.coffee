should = require("should")
assert = require("assert")
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
cache = require '../index'
ntimer = require 'ntimer'

describe "Cache", ->

  it "set expiry", ( done ) ->
    cache expiry : '1m'
    .expiry().should.equal 1000 * 60
    done()

  it "insert item", ( done ) ->
    cache()
    .set 'foo', 'bar'
    .get('foo').should.equal 'bar'
    done()

  it "emits 'set' on insert", ( done ) ->
    cache()
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .set 'foo', 'bar'

  it "emits 'error' on loader error", ( done ) ->
    cache()
    .on 'error', ( err ) -> done()
    .get 'abc', -> throw new Error 'test'

  it "global loader (function)", ( done ) ->
    loader = ( k ) -> 'bar'
    cache()
    .loader loader
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo').should.equal 'bar'

  it "global loader (object)", ( done ) ->
    loader =
      load : ( k ) -> 'bar'
    cache()
    .loader loader
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo').should.equal 'bar'

  it "local loader", ( done ) ->
    loader = -> 'bar'
    cache()
    .on 'set', ( k, v ) ->
      k.should.equal 'foo'
      v.should.equal 'bar'
      done()
    .get('foo', loader).should.equal 'bar'

  it "evict by size", ( done ) ->
    evictionCount = 0
    c = cache maxSize : 2
    .on 'delete', ( k, v, reason ) ->
      reason.should.equal 'size'
      k = Number k
      k.should.equal evictionCount++
      done() if k is 2

    c.set i, i for i in [ 0..4 ]

  it 'evict by time', ( done ) ->
    d = false
    c = cache expiry : '3s'
    .on 'delete', ( k, v, reason ) ->
      reason.should.equal 'expiry'
      unless d
        done()
        d = true
    .set 'foo', 'bar'

    ntimer.autoRepeat 'get', '1s', 10
    .on 'timer', ( n, i ) -> c.get 'foo'

  it 'stats - evict by size', ( done ) ->
    c = cache expiry : '10s', maxSize : 3
    count = 100
    for i in [ 1..count ]
      c.set i, i

    for i in [ 1..count * 1000 ]
      c.get Math.floor(Math.random() * count * 2)

    console.log JSON.stringify c.stats(), null, 2
    done()

