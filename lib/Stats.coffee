module.exports = class Stats

  constructor : ->
    @hitCount = 0
    @missCount = 0
    @loadSuccessCount = 0
    @loadErrorCount = 0
    @evictionCount = 0

  hit : => @hitCount++
  miss : => @missCount++
  evict : => @evictionCount++
  loadOk : => @loadSuccessCount++
  loadError : => @loadSuccessCount++

  requestCount : => @hitCount + @missCount

  loadCount : => @loadSuccessCount + @loadErrorCount

  hitRate : =>
    requestCount = @requestCount()
    return 1 if requestCount is 0
    @hitCount / requestCount

  missRate : =>
    requestCount = @requestCount()
    return 0 if requestCount is 0
    @missCount / requestCount

  toObject : =>
    hits : @hitCount
    misses : @missCount
    evictions : @evictionCount
    hitRate : @hitRate()
    missRate : @missRate()
    loads : @loadCount()

  toString : =>
    x = @toObject()
    ("#{k}: #{v}" for own k,v of x).join ", "
