define ['lib/version', 'lib/hullbase', 'lib/client/api/params', 'lib/client/api/dataModels'], (version, base, apiParams, dataModels) ->

  (app) ->
    rpc = false
    module =
      require:
        paths:
          easyXDM: 'components/easyXDM/easyXDM'
          backbone: 'components/backbone/backbone'
          cookie: 'components/jquery.cookie/jquery.cookie'
        shim:
          easyXDM: { exports: 'easyXDM' }
          backbone: { exports: 'Backbone', deps: ['underscore', 'jquery'] }

      # Builds the URL used by easyXDM
      # Based upon the (app) configuration
      buildRemoteUrl: (config)->
        remoteUrl = "#{config.orgUrl}/api/v1/#{config.appId}/remote.html?v=#{version}"
        remoteUrl += "&js=#{config.jsUrl}"  if config.jsUrl
        remoteUrl += "&uid=#{config.uid}"   if config.uid
        remoteUrl

      initialize: (app)->
        core    = app.core
        sandbox = app.sandbox

        _         = require('underscore')
        Backbone  = require('backbone')
        easyXDM   = require('easyXDM')

        slice = Array.prototype.slice


        #
        #
        # Strict API
        #
        #


        ###
        # Sends the message described by @params to easyXDM
        # @param {Object} contains the provider, uri and parameters for the message
        # @param {Function} optional a success callback
        # @param {Function} optional an error callback
        # @return {Promise}
        ###
        message = (params, callback, errback)->
          console.error("Api not initialized yet") unless rpc
          promise = core.data.deferred()

          onSuccess = (res)->
            if res.provider == 'hull' && res.headers
              setCurrentUser(res.headers)
            res = res.response || {};
            callback(res)
            promise.resolve(res)
          onError = (err)->
            errback(err)
            promise.reject(err)
          rpc.message params, onSuccess, onError
          promise

        # Main method to request the API
        api = ->
          message.apply(api, apiParams.parse(slice.call(arguments)))

        # Method-specific function
        _.each ['get', 'post', 'put', 'delete'], (method)->
          api[method] = ()->
            args = apiParams.parse (slice.call(arguments))
            req         = args[0]
            req.method  = method
            message.apply(api, args)

        core.data.api = api
        dataModels.initialize api, core.data.deferred, core.mediator
        core.track = sandbox.track = (eventName, params)->
          core.data.api({provider:"track", path: eventName}, 'post', params)



        api.model = dataModels.createModel

        api.collection = (path)->
          throw new Error('A model must have an path...') unless path?
          dataModels.createCollection path



        #
        # Initialization
        #

        initialized = core.data.deferred()

        onRemoteMessage = -> console.warn("RPC Message", arguments)

        timeout = setTimeout(
          ()->
            initialized.reject('Remote loading has failed. Please check "orgUrl" and "appId" in your configuration. This may also be about connectivity.')
          , 30000)

        onRemoteReady = (remoteConfig)->
          data = remoteConfig.data

          if data.headers && data.headers['Hull-User-Id']
            app.core.currentUser = {
              id:   data.headers['Hull-User-Id'],
              sig:  data.headers['Hull-User-Sig']
            }

          window.clearTimeout(timeout)
          app.config.assetsUrl            = remoteConfig.assetsUrl
          app.config.services             = remoteConfig.services
          app.config.widgets.sources.hull = remoteConfig.baseUrl + '/widgets'
          app.sandbox.config ?= {}
          app.sandbox.config.debug        = app.config.debug
          app.sandbox.config.assetsUrl    = remoteConfig.assetsUrl
          app.sandbox.config.appId        = app.config.appId
          app.sandbox.config.orgUrl       = app.config.orgUrl
          app.sandbox.config.services     = remoteConfig.services
          app.sandbox.config.entity_id    = data.entity?.id
          for m in ['me', 'app', 'org', 'entity']
            attrs = data[m]
            if attrs
              attrs._id = m
              dataModels.createModel(attrs)

          initialized.resolve(data)

        initialized.reject(new TypeError 'no organizationURL provided. Can\'t proceed') unless app.config.orgUrl
        initialized.reject(new TypeError 'no applicationID provided. Can\'t proceed') unless app.config.appId

        rpc = new easyXDM.Rpc({
          remote: module.buildRemoteUrl(app.config)
        }, {
          remote: { message: {}, ready: {} }
          local:  { message: onRemoteMessage, ready: onRemoteReady }
        })

        initialized

      afterAppStart: (app)->

        base.me     = dataModels.createModel({_id: 'me'});
        base.app    = dataModels.createModel({_id: 'me'});
        base.org    = dataModels.createModel({_id: 'me'});

        app.core.mediator.emit  'hull.currentUser', app.core.currentUser
        app.core.mediator.on    'hull.currentUser', (headers)->
          dataModels.createModel({id: headers.id, _id: 'me'}) if headers?.id


    module
