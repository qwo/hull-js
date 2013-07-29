define ['underscore', 'lib/utils/promises', 'lib/client/data/datasource'], (_, promises, Datamapper)->
  cache = {}
  keywordAliases =
    me: null
    app: null
    org: null

  get: (id)->
    isKeyword = _.indexOf(_.keys(keywordAliases), id) != -1
    if isKeyword
      realId = keywordAliases[id]
      if realId
        obj = realId
      else
        obj = new Datamapper(id)
        obj.fetch().then (realObj)->
          realObj._alias = id
          keywordAliases[id] = realObj
          cache[realObj.get('id')] = realObj
        keywordAliases[id] = obj
    else
      if !cache[id]
        cache[id] = new Datamapper(id)
        cache[id].fetch().then (realObj)->
          cache[realObj.get('id')] = realObj
      obj = cache[id]
    if obj instanceof Datamapper
      dfd = obj.fetch()
    else
      dfd = promises.deferred()
      dfd.resolve(obj)
    dfd
  refresh: ->
    dfd = promises.deferred()
    @get().then (obj)->
      obj.fetch().then (obj)->
        dfd.resolve obj
    dfd

