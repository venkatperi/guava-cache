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
  loadError : => @loadErrorCount++

  requestCount : => @hitCount + @missCount
  loadCount : => @loadSuccessCount + @loadErrorCount

  _computeRates : =>
    rates= {}
    [rates.hit, rates.miss] =
      @_rates @hitCount, @missCount, @requestCount()
    [rates.loadOk, rates.loadErr] =
      @_rates @loadSuccessCount, @loadErrorCount, @loadCount()
    rates

  _rates : ( ok, err, total ) ->
    return [ 1, 0 ] if total is 0
    [ ok / total, err / total ]

  toObject : =>
    @_computeRates()
    hits : @hitCount
    misses : @missCount
    evictions : @evictionCount
    rates : @_computeRates()
   
  toString : =>
    x = @toObject()
    ("#{k}: #{v}" for own k,v of x).join ', '
