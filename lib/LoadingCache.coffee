{EventEmitter} = require 'events'
prop = require 'prop-it'
millisecond = require 'millisecond'
Stats = require './Stats'
moment = require 'moment'
seqx = require 'seqx'
flatten = require 'flatten'

class Meta
  constructor : ->
    @_insertedAt = moment()
    @_lastUsedAt = moment()
    @_useCount = 0

  diff : ( now ) => now.diff @_insertedAt
  use : =>
    @_lastUsedAt = moment()
    @_useCount++

module.exports = class LoadingCache extends EventEmitter

  constructor : ( opts = {} )->
    expiry = opts.expiry ? '1h'
    @_cache = new Map()
    @_stats = new Stats()
    @_ex = seqx()

    prop @, { name : 'expiry', convert : millisecond, initial : expiry }
    prop @, { name : 'maxSize', initial : opts.maxSize ? 1000 }
    prop @, { name : 'stats', getter : => @_stats.toObject() }
    prop @, { name : 'loader' }

  has : ( k ) => @_cache.has k

  size : => @_cache.size

  delete : ( k ) => @_remove k, "explicit"

  deleteAll : ( keys... ) =>
    keys = flatten keys
    keys = @_keys() if keys.length is 0
    @delete k for k in keys

  cleanup : => @_ex.add @_evictBySize, @_evictByTime

  refresh : ( k ) => @_ex.add @_refresh k

  get : ( k, loader ) =>
    if @has k
      v = @_cache.get(k)
      now = moment()
      if v.meta.diff(now) <= @expiry()
        @_stats.hit()
        v.meta.use()
        return v.data

    @_stats.miss()
    @_refresh k, loader

  set : ( k, v ) =>
    @_cache.set k, data : v, meta : new Meta()
    @emit "set", k, v
    @_postWrite()
    @

  _keys : => @_findFirstWith -> true

  _refresh : ( k, loader ) =>
    return unless loader ?= @_loader
    load = loader.load ? loader
    try
      v = load k
      @set k, v
      @_stats.loadOk()
      return v
    catch err
      @_stats.loadError()

  _evictBySize : =>
    return if @size() <= @maxSize()
    n = @size() - @maxSize()
    iter = @_cache.keys()
    keys = (iter.next().value for i in [ 0..n - 1 ])
    for k in keys
      @_remove k, "size"
      @_stats.evict()

  _evictByTime : =>
    for k in @_findExpiredKeys moment()
      @_remove k, "expiry"
      @_stats.evict()

  _findExpiredKeys : ( now )=>
    expiry = @expiry()
    @_findFirstWith ( k, v ) ->
      v.meta.diff(now) > expiry

  _findFirstWith : ( fn )=>
    keys = []
    iter = @_cache.keys()
    while k = iter.next().value
      break unless fn(k, @_cache.get k)
      keys.push k
    keys

  _remove : ( k, reason ) =>
    return unless @has k
    v = @_cache.get(k).data
    @_cache.delete k
    @emit "delete", k, v, reason
    @

  _postWrite : => @cleanup()

