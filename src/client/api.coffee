define ['underscore', 'lib/api', 'lib/utils/promises', 'lib/client/data/objectResolver'], (_, apiModule, promises, ObjectResolver) ->

  (app) ->
    models = {}

    clearModelsCache =->
      models = _.pick(models, 'me', 'app', 'org')


    module =
      require:
        paths:
          cookie: 'components/jquery.cookie/jquery.cookie'

      initialize: (app)->
        core    = app.core
        sandbox = app.sandbox

        slice = Array.prototype.slice

        apiModule = apiModule(app.config)
        apiModule.then (apiObj)->
          core.data.api= apiObj.api
          core.track = sandbox.track = (eventname, params)->
            core.data.api({provider:"track", path: eventname}, 'post', params)
          core.flag = sandbox.flag = (id)->
            core.data.api({provider:"hull", path:[id, 'flag'].join('/')}, 'post')

          #
          #
          # models/collection related
          #
          #


        #
        # initialization
        #

        initialized = core.data.deferred()
        apiModule.then (apiObj)->
          remoteConfig = apiObj.remoteConfig
          app.config.assetsUrl            = remoteConfig.assetsUrl
          app.config.services             = remoteConfig.services
          app.config.widgets.sources.hull = remoteConfig.baseUrl + '/widgets'
          app.sandbox.config ?= {}
          app.sandbox.config.debug        = app.config.debug
          app.sandbox.config.assetsUrl    = remoteConfig.assetsUrl
          app.sandbox.config.appId        = app.config.appId
          app.sandbox.config.orgUrl       = app.config.orgUrl
          app.sandbox.config.services     = remoteConfig.services
          app.sandbox.config.entity_id    = remoteConfig.data.entity?.id
          app.sandbox.isAdmin             = remoteConfig.access_token?

          app.sandbox.login = (provider, opts, callback=->)->
            apiObj.auth.login.apply(undefined, arguments).then ->
              app.core.mediator.emit 'hull.auth.complete'
              ObjectResolver.refresh('me').then (me)->
                app.core.mediator.emit('hull.login', me)
            , ->
              app.core.mediator.emit 'hull.auth.failure'

          app.sandbox.logout = (callback=->)->
            apiObj.auth.logout(callback).then ->
              app.core.mediator.emit('hull.logout')
              ObjectResolver.resolve('me').then (me)-> me.clear()

          # for m in ['me', 'app', 'org', 'entity']
          #   attrs = data[m]
          #   if attrs
          #     attrs._id = m
          #     rawFetch(attrs, true)

          initialized.resolve()

        apiModule.fail (e)->
          initialized.reject e
        initialized.reject(new TypeError 'no organizationURL provided. Can\'t proceed') unless app.config.orgUrl
        initialized.reject(new TypeError 'no applicationID provided. Can\'t proceed') unless app.config.appId

        initialized

      afterAppStart: (app)->
        app.core.mediator.on    'hull.login', clearModelsCache
        app.core.mediator.on    'hull.logout', clearModelsCache
    module
