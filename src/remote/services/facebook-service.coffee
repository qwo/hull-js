define ->

  slice = Array.prototype.slice

  ensureLoggedIn = (base)->
    ->
      args = slice.call(arguments)
      FB.getLoginStatus ->
        base.apply(undefined, args)
      , true

  resp = (req, route, callback, errback)->
    (res)->
      if (res && !res.error)
        callback(res)
      else
        if (res)
          errorMsg = "[FB Error] " + res.error.type + " : " + res.error.message
        else
          errorMsg = "[FB Error] Unknown error"
        errback(errorMsg, { result: res, request: req })

  api = ensureLoggedIn (req, route, callback, errback)->
    path = req.path.replace(/^\/?facebook\//, '')
    FB.api path, req.method, req.params, resp(req, route, callback, (msg, res)-> res.time = new Date(); callback(res))

  fql = ensureLoggedIn (req, route, callback, errback)->
    FB.api({ method: 'fql.query', query: req.params.query }, resp(req, route, callback, errback))

  # The actual extension...
  config:
    require:
      paths:
        facebook: "https://connect.facebook.net/en_US/all"
      shim:
        facebook: { exports: 'FB' }

  init: (env)->
    dfd = env.core.data.deferred()
    FB.init(env.config.services.facebook)
    FB.getLoginStatus dfd.resolve
    env.core.services.add([ { path: "/facebook/fql",    handler: fql } ])
    env.core.services.add([ { path: "/facebook/*path",  handler: api } ])

    dfd


