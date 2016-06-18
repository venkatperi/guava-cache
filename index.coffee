Cache = require './lib/LoadingCache'

cache = ( opts ) -> new Cache opts
 
cache.Cache = Cache

module.exports = cache