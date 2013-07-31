define ['underscore', 'lib/utils/promises', './datasource', './cache'], (_, promises, Datamapper, cache)->
  # get or set, acually
  get: (id)->
    if cache.has(id)
      obj = cache.get id
    else
      obj = new Datamapper(id)
      obj = obj.fetch()
      cache.set id, obj
    obj


  refresh: (id)->
    dfd = promises.deferred()
    @get(id).then (obj)->
      obj.fetch().then (obj)->
        dfd.resolve obj
    dfd

