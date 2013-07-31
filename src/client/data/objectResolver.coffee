define ['underscore', 'lib/utils/promises', './datasource', './urlMapper', './cache'], (_, promises, Datamapper, urlMapper, cache)->
  # get or set, acually
  getOrCreate = (id)->
    if cache.has(id)
      obj = cache.get id
    else
      obj = new Datamapper(id)
      obj = obj.fetch()
      cache.set id, obj
    obj

  # Pretty pointless for now, more to come
  resolve: (id, bindings={})->
    getorCreate(urlMapper(id, bindings).path)


  refresh: (id)->
    dfd = promises.deferred()
    getOrCreate(id).then (obj)->
      obj.fetch().then (obj)->
        dfd.resolve obj
    dfd

