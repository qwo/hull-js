define ['underscore', 'lib/api'], (_, api)->
  methodMap =
    'create': 'post'
    'update': 'put'
    'delete': 'delete'
    'read':   'get'

  (method, model, options={})->
    url   = if _.isFunction(model.url) then model.url() else model.url
    verb  = methodMap[method]

    data = options.data
    if !data? && model && (method == 'create' || method == 'update' || method == 'patch')
      data = options.attrs || model.toJSON(options)

    dfd = api(url, verb, data)
    dfd.then(options.success)
    dfd.then (resolved)->
      model.trigger('sync', model, resolved, options)
    dfd.fail(options.error)
    dfd.fail (rejected)->
      model.trigger 'error', model, rejected, options
    dfd


