# guava-cache
### A loading, memory cache for nodejs based on google's guava.

[![Build Status](https://travis-ci.org/venkatperi/gauva-cache.svg?branch=master)](https://travis-ci.org/venkatperi/gauva-cache)

## Installation

Install with npm:

```shell
npm install guava-cache --save
```

## Examples

### Create Cache

```coffeescript
guavaCache = require 'guava-cache'

# 6 hour eviction, 500 items limit
cache = guavaCache expiry: '6h', maxItems: 500
```

### Global Loader

```coffeescript
loader = (key) ->
  return 'bar' if key is 'foo' 
  throw new Error 'key not found'
  
cache = guavaCache().loader(loader)
cache.get 'foo'
# => 'bar'
cache.get 'abc'
# => undefined
```

### Local Loader
```coffeescript
loader = (key) ->
  return 'bar' if key is 'foo' 
  throw new Error 'key not found'
  
cache = guavaCache()
cache.get 'foo', loader
# => 'bar'
cache.get 'abc'
# => undefined
```
### Removal Listener

```coffeescript
cache.on "delete", (key, value, reason) ->
  value.close() # do something with value 
# => reason: 'expiry'
# => reason: 'size'
# => reason: 'explicit'
```

### Stats

```coffeescript

cache.stats()
###
{
  "hits": 49897,
  "misses": 50103,
  "evictions": 0,
  "rates": {
    "hit": 0.49897,
    "miss": 0.50103,
    "loadOk": 1,
    "loadErr": 0
  }
}
###
```



## Applicability

Caches are tremendously useful in a wide variety of use cases. For example, you should consider using caches when a value is expensive to compute or retrieve, and you will need its value on a certain input more than once.

A Cache is similar to `Map`, but not quite the same. The most fundamental difference is that a Map persists all elements that are added to it until they are explicitly removed. A Cache on the other hand is generally configured to evict entries automatically, in order to constrain its memory footprint. In some cases a loading Cache can be useful even if it doesn't evict entries, due to its automatic cache loading.

Generally, `guava-cache`is applicable whenever:

* You are willing to spend some memory to improve speed.
* You expect that keys will sometimes get queried more than once.
* Your cache will not need to store more data than what would fit in RAM. (caches are **local** to a single run of your application. They **do not store** data in files, or on outside servers. If this does not fit your needs, consider a tool like `Memcached`.)

If each of these apply to your use case, then `guava-cache` could be right for you!

## Population

The first question to ask yourself about your cache is: is there some sensible default function to load or compute a value associated with a key? If so, you should proivide a global loader via `cache.loader(loader)`. If not, or if you need to override the default, but you still want atomic "get-if-absent-compute" semantics, you should pass a `loader` into a get call `cache.get(key, loader)`. Elements can be inserted directly, using `cache.put(key,value)`, but automatic cache loading is preferred as it makes it easier to reason about consistency across all cached content.

### Cache Loader

A cache loader can be:

* `loader(key) -> value` a `{Function}` which returns a value for a key or
* `loader.load(key) -> value` an `{Object}` a `load` function which returns a value for a key.

A cache loader can be set with the `cache.loader(myLoader)` function.

The canonical way to query a `guava-cache` is with the method `cache.get(key)`. This will either return an already cached value, or else use the cache's `loader` to atomically load a new value into the cache. 

> **Note:** A loader must **throw** an error is a key **cannot be loaded** and must not be inserted in the cache. Simply returning undefined for a non-existent key will cause the key to be inserted in to the cache.

### Local Loader

The `cache.get(key, loader)` method returns the value associated with the key in the cache, or computes it from the specified loader and adds it to the cache. This method provides a simple substitute for the conventional "if cached, return; otherwise create, cache and return" pattern.

### Inserted Directly

Values may be inserted into the cache directly with `cache.put(key, value)`. This overwrites any previous entry in the cache for the specified key. 

## Eviction

`guava-cache` provides two types of eviction: size-based and time-based.

### Size-based Eviction

Call `cache.maxSize(size)` to prevent the cache from growing beyond a certain size (number of elements). Currently, the oldest entries by insertion time are evicted. 

### Timed Eviction

Expire entries after the specified duration has passed since the entry was created, or the most recent replacement of the value. This could be desirable if cached data grows stale after a certain amount of time.

Timed expiration is performed with periodic maintenance during writes.

### Explicit Removals

At any time, you may explicitly invalidate cache entries rather than waiting for entries to be evicted. This can be done:

* individually using `cache.delete(key)`
* in bulk, using `cache.deleteAll(keys…)`
* all entries, using `cache.deleteAll()`

## Cleanup

`guava-cache`does **not** perform cleanup and evict values "automatically," or instantly after a value expires, or anything of the sort. Instead, it performs small amounts of maintenance during write operations, or during occasional read operations if writes are rare.

You may call `cache.cleanup()` for explicit cleanup or schedule a periodic cleanup:

```coffeescript
setInterval (-> cache.cleanup()), 3600000	#hourly cleanup
```

## Refresh

Refreshing a key loads a new value for the key (by calling `cache.refresh(key)`). This is an async opertion. The old value (if any) is returned while the key is being refreshed. This is in contrast to eviction, which forces retrievals to wait until the value is loaded anew.

```coffeescript
cache.refresh(key)	# async operation
```

## Statistics

The `cache.stats()` method returns an object which provides statistics such as the hit rate, eviction count etc.

# API

## Create Cache

### cache(opts)

Creates a cache with the following options:

* **expiry** Expire entries after this time. Can be a `{Number}` in milliseconds or a `{String}` (uses [millisecond)](https://github.com/unshiftio/millisecond) module). Defaults to one hour `'1h'`.
* **maxSize** sets the maximum size of the cache. Default is `1000`.

## Methods

### has(key)

Returns a boolean asserting whether a value has been associated to the key in the cache or not.

### size()

Returns the number of entries in the cache.

### delete(key)

Removes any value associated to the key. `cache.has(key)` will return false afterwards. Returns `this` for chaining. Emits a `delete` event with the reason 'explicit'.

### deleteAll([keys])

Removes all of the keys in the given key argument list or array by calling `cache.delete(key)` for each key. If no arguments are supplied, `deleteAll()` removes all keys in the cache. 

### cleanup()

Explicitly invokes async cleanup operations on the cache including eviction by time and eviction by size.

### refresh(key)

Begins a refresh operation for the given **key**. This is an async opertion. The old value (if any) is returned while the key is being refreshed. This is in contrast to eviction, which forces retrievals to wait until the value is loaded anew.

### get(key[, loader])

Returns the value associated to the key if the key exists in the cache and has not expired. Otherwise  `get` will attempt to load a value by calling the local  **loader** if one is provided, or the global loader (set via the `cache.loader(loader)`). If a value is loaded, it is inserted in the cache and returned. If the loader throws an error, `get` returns undefined. 

### set(key, value)

Sets the value for the key in the `cache`. Returns the `cache` object for chaining. Emits a `set` event.

### stats()

Returns a object with cache statistics, including:

* number of hits & misses
* number of evictions
* hit / miss rate
* load success / error rate

## Events

`guava-cache` emits the following events:

### on("set", key, value)

Emitted for each **key**,**value** insertion.

### on("delete", key, value, reason)

Emitted when keys are removed. Reason `{String}` can be any of:

- `size` for size based evictions
- `expiry` for time based eviction
- `explicit` for user / explicit removals.





