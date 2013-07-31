# Objects passed to cache MUST have a fetch method
# Typically, they're meant to be Datamapper instances

define ['underscore'], (_)->
  cache = {}
  keywordAliases =
    me: null
    app: null
    org: null

  _isKeyword = (id)->
    _.indexOf(_.keys(keywordAliases), id) != -1

  has: (id)->
    !!(keywordAliases[id] || cache[id])

  get: (id)->
    if _isKeyword(id)
      obj = keywordAliases[id]
    else
      obj = cache[id]
    obj

  set:(id, obj, force=false)->
    if _isKeyword(id)
      throw new Error('already cached') if (force and keywordAliases[id])
      obj.then (realObj)->
        realObj._alias = id
        realId = realObj.get('id')
        cache[realId] = obj if realId
      keywordAliases[id] = obj
    else
      throw new Error('already cached') if (force and cache[id])
      cache[id] = obj

