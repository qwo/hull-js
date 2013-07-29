define ['lib/utils/promises', 'underscore', 'lib/api'], (promises, _, api)->
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

    deferred = promises.deferred()
    deferred.then options.success
    deferred.fail options.error
    api().then (apiObj)->
      dfd = apiObj.api(url, verb, data)
      dfd.then (data)->
        deferred.resolve data || {}
      dfd.fail (rejected)->
        deferred.reject rejected
    deferred.promise()


