hash = try JSON.parse(atob(document.location.hash.replace('#', '')))
if window.opener && window.opener.Hull && hash?
  try
    window.opener.__hull_login_status__(hash)
    window.close()
  catch e
    console.warn('Error: ' + e)

define ['underscore', '../utils/promises', '../utils/version'], (_, promises, version)->
  (apiFn, config, authServices=[]) ->
    authenticating = null
    _popupInterval = null

    signUp = (user) ->
      apiFn('users', 'post', user)

    login = (loginOrProvider, optionsOrPassword, callback) ->
      throw new TypeError("'loginOrProvider' must be a String") unless _.isString(loginOrProvider)

      if _.isString(optionsOrPassword)
        promise = apiFn('users/login', 'post', { login: loginOrProvider, password: optionsOrPassword })
      else
        promise = loginWithProvider(loginOrProvider, optionsOrPassword).then ->
          apiFn('me')

      promise.then(callback) if _.isFunction(callback)

      promise

    loginWithProvider = (providerName, opts)->
      return module.isAuthenticating() if module.isAuthenticating()

      providerName = providerName.toLowerCase()
      throw "No authentication service #{providerName} configured for the app" unless ~(_.indexOf(authServices, providerName + '_app'))

      authenticating = promises.deferred()
      authenticating.providerName = providerName

      authUrl = module.authUrl(config, providerName, opts)
      module.authHelper(authUrl)

      authenticating.promise

    logout = (callback)->
      promise = apiFn('logout')
      promise.done ->
        callback() if _.isFunction(callback)
      promise

    onCompleteAuthentication = (hash)->
      _auth = authenticating
      return unless authenticating

      if hash.success
        authenticating.resolve({})
      else
        authenticating.reject(hash.error)

      authenticating = null
      clearInterval(_popupInterval)
      _popupInterval = null
      _auth

    # Generates the complete URL to be reached to validate login
    generateAuthUrl = (config, provider, opts)->
      module.createCallback()

      auth_params = opts || {}
      auth_params.app_id        = config.appId
      # The following is here for backward compatibility. Must be removed at first sight next time
      auth_params.callback_url  = config.callback_url || config.callbackUrl || module.location.toString()
      auth_params.auth_referer  = module.location.toString()
      auth_params.version       = version
      querystring = _.map auth_params,(v,k) ->
        encodeURIComponent(k)+'='+encodeURIComponent(v)
      .join('&')
      "#{config.orgUrl}/auth/#{provider}?#{querystring}"

    module =
      isAuthenticating: -> authenticating?
      location: document.location
      authUrl: generateAuthUrl
      createCallback: ->
        window.__hull_login_status__ = (hash) ->
          window.__hull_login_status__ = null
          onCompleteAuthentication(hash)
      authHelper: (path)->
        w = window.open(path, "_auth", 'location=0,status=0,width=990,height=600')
        _popupInterval = w? && setInterval ->
          if w?.closed
            onCompleteAuthentication({ success: false, error: { reason: 'window_closed' } })
        , 200
      onCompleteAuth: onCompleteAuthentication

    authModule =
      signUp: signUp
      login: login
      logout: logout
      isAuthenticating: module.isAuthenticating

    authModule
