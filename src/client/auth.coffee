define ->

  # Holds the state of the authentication process
  # @type {Promise|Boolean}
  authenticating = false

  (app) ->
    loggedIn = ->
      identities = app.sandbox.data.api.model('me').get('identities')
      return false unless identities
      ret = {}
      identities.map (i)-> ret[i.provider] = i
      ret

    # Starts the login process
    # @throws Error with invalid providerName
    # @returns {Promise|false}
    login = (providerName, opts, callback=->)->
      return module.isAuthenticating() if module.isAuthenticating()

      throw 'The provider name must be a String' unless _.isString(providerName)
      authServices = app.sandbox.config.services.types.auth || []
      providerName = providerName.toLowerCase()
      throw "No authentication service #{providerName} configured for the app" unless ~(authServices.indexOf(providerName + '_app'))

      authenticating = app.sandbox.data.deferred()
      authenticating.providerName = providerName
      authenticating.done callback if _.isFunction(callback)

      authUrl = module.authUrl(app.config, providerName, opts)
      module.authHelper(authUrl)

      authenticating #TODO It would be better to return the promise



    # Starts the logout process
    # @returns {Promise}
    # @TODO Misses a `dfd.fail`
    logout = (callback=->)->
      api = app.sandbox.data.api;
      dfd = api('logout')
      dfd.done ->
        app.core.setCurrentUser(false)
        api.model('me').clear()
        api.model('me').trigger('change')
        callback() if _.isFunction(callback)
      dfd #TODO It would be better to return the promise



    # Callback executed on successful authentication
    onCompleteAuthentication = ()->
      isAuthenticating = module.isAuthenticating()
      return unless isAuthenticating && isAuthenticating.state() == 'pending'
      providerName = isAuthenticating.providerName
      dfd = isAuthenticating
      try
        me = app.sandbox.data.api.model('me')
        dfd.done -> me.trigger('change')
        me.fetch(silent: true).then(dfd.resolve, dfd.reject)
      catch err
        console.error "Error on auth promise resolution", err
      finally
        authenticating = false

    setCurrentUser = (headers={})->
      return unless app.config.appId
      cookieName = "hull_#{app.config.appId}"
      currentUserId = app.core.currentUser?.id
      if headers && headers['Hull-User-Id'] && headers['Hull-User-Sig']
        val = btoa(JSON.stringify(headers))
        $.cookie(cookieName, val, path: "/")
        if currentUserId != headers['Hull-User-Id']
          app.core.currentUser = {
            id:   headers['Hull-User-Id'],
            sig:  headers['Hull-User-Sig']
          }
          app.core.mediator.emit('hull.currentUser', app.core.currentUser)
      else
        $.removeCookie(cookieName, path: "/")
        app.core.currentUser = false
        app.core.mediator.emit('hull.currentUser', app.core.currentUser) if currentUserId

      app.sandbox.config ?= {}
      app.sandbox.config.curentUser = app.core.currentUser


    # Generates the complete URL to be reached to validate login
    generateAuthUrl = (config, provider, opts)->
      auth_params = opts || {}
      auth_params.app_id        = config.appId
      auth_params.callback_url  = config.callback_url || module.location.toString()
      auth_params.auth_referer  = module.location.toString()

      "#{config.orgUrl}/auth/#{provider}?#{$.param(auth_params)}"


    #
    # Module Definition
    #

    module =
      login: login,
      logout: logout,
      isAuthenticating: -> authenticating #TODO It would be better to return Boolean (isXYZ method)
      location: document.location
      authUrl: generateAuthUrl
      authHelper: (path)-> window.open(path, "_auth", 'location=0,status=0,width=990,height=600')
      onCompleteAuth: onCompleteAuthentication
      initialize: ->
        # Tell the world that the login process has ended
        app.core.mediator.on "hull.authComplete", onCompleteAuthentication

        # Are we authenticating the user ?
        app.sandbox.authenticating = module.isAuthenticating

        app.sandbox.login = login
        app.sandbox.logout = logout
        app.core.setCurrentUser = setCurrentUser
        app.sandbox.loggedIn = loggedIn

    module
