define ['underscore'], (_)->
  #
  # Parses the URI to replace placeholders with actual values
  #
  (uri, bindings)->
    if _.isString(uri)
      uri =
        path: uri
        provider: 'hull'
    else if _.isObject(uri) && !_.isFunction(uri)
      throw _errDefinition unless uri.path
    uri.provider = uri.provider || 'hull'
    placeHolders = uri.path.match(/(\:[a-zA-Z0-9-_]+)/g)
    return uri unless placeHolders
    for p in placeHolders
      _key = p.slice(1)
      unless _.has(bindings, _key)
        throw new Error "Cannot resolve datasource binding #{p}"
      uri.path = uri.path.replace p, bindings[_key]
    uri

