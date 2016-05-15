{EventEmitter} = require 'events'
prop = require 'prop-it'
millisecond = require 'millisecond'
Stats = require './Stats'
ntimer = require 'ntimer'
moment = require 'moment'

module.exports = class LoadingCache extends EventEmitter

  constructor : ( opts = {} )->
    expiry = opts.expiry ? '1h'
    @_cache = new Map()
    @_meta = new Map()
    @_stats = new Stats()

    prop @, { name : 'expiry', convert : millisecond, initial : expiry }
    prop @, { name : 'maxSize', initial : opts.maxSize ? 1000 }
    prop @, { name : 'stats', getter : => @_stats.toObject() }
    prop @, { name : 'loader' }

    @_evictionTimer = ntimer.autoRepeat 'eviction', opts.timer or '1m'
    .on 'timer', @_onEvictionTimer

  has : ( k ) => @_cache.has k

  size : => @_cache.size

  delete : ( k ) => @_remove k, "removed by user"

  get : ( k, loader ) =>
    if @has k
      @_stats.hit()
      return @_cache.get k

    @_stats.miss()
    loader ?= @_loader
    return unless loader?
    try
      v = loader k
      @set k, v
      @_stats.loadOk()
      return v
    catch err
      @_stats.loadError()

  set : ( k, v ) =>
    @_cache.set k, v
    @_meta.set k, insertedAt : moment()
    @emit "set", k, v
    @

  _evictBySize : =>
    return if @size() <= @maxSize()
    n = @size() - @maxSize()
    iter = @_cache.keys()
    keys = (iter.next().value for i in [ 0..n - 1 ])
    for k in keys
      @_remove k, "maximum size exceeded"
      @_stats.evict()

  _evictByTime : =>
    now = moment()
    keys = []
    do =>
      iter = @_cache.keys()
      while k = iter.next().value
        meta = @_meta.get k
        diff = now.diff meta.insertedAt
        return if diff < @expiry()
        keys.push k
    for k in keys
      @_remove k, "expired"
      @_stats.evict()

  _remove : ( k, reason ) =>
    return unless @has k
    @_cache.delete k
    @_meta.delete k
    @emit "delete", k, reason
    @

  _onEvictionTimer : ( name, count ) =>
    @_evictBySize()
    @_evictByTime()
