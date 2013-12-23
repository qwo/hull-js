define ['underscore', 'lib/utils/promises', 'aura/aura', 'lib/utils/handlebars', 'lib/hull.api', 'lib/utils/emitter', 'lib/client/component/registrar', 'lib/helpers/login'], (_, promises, Aura, Handlebars, HullAPI, emitterInstance, componentRegistrar, loginHelpers) ->

  hullApiMiddleware = (api)->
    name: 'Hull'
    initialize: (app)->
      app.core.mediator.setMaxListeners(100)
      app.core.data.hullApi = api
    afterAppStart: (app)->
      _ = app.core.util._
      sb = app.sandboxes.create();
      # _.extend(HullDef, sb);
      # After app init, call the queued events

  setupApp = (app, api)->
    app
      .use(hullApiMiddleware(api))
      .use('aura-extensions/aura-base64')
      .use('aura-extensions/aura-cookies')
      .use('aura-extensions/aura-backbone')
      .use('aura-extensions/aura-moment')
      .use('aura-extensions/aura-twitter-text')
      .use('aura-extensions/hull-reporting')
      .use('aura-extensions/hull-entities')
      .use('aura-extensions/hull-utils')
      .use('aura-extensions/aura-form-serialize')
      .use('aura-extensions/aura-component-validate-options')
      .use('aura-extensions/aura-component-require')
      .use('aura-extensions/hull-component-normalize-id')
      .use('aura-extensions/hull-component-reporting')
      .use('lib/client/component/api')
      .use('lib/client/component/actions')
      .use('lib/client/component/component')
      .use('lib/client/component/templates')
      .use('lib/client/component/datasource')

  init: (config)->
    appPromise = HullAPI.init(config).then (successResult)->
      app = new Aura(_.extend config, mediatorInstance: successResult.eventEmitter)
      deps = 
        api: successResult.raw.api
        authScope: successResult.raw.authScope
        remoteConfig: successResult.raw.remoteConfig
        login: successResult.api.login
        logout: successResult.api.logout
      app: setupApp(app, deps)
      api: successResult.api
    appPromise
  success: (appParts)->
    booted = HullAPI.success(appParts)
    booted.component = componentRegistrar(define)
    booted.util.Handlebars = Handlebars
    booted.define = define
    booted.parse = (el, options={})->
      appParts.app.sandbox.start(el, options)
    appParts.app.start({ components: 'body' }).then ->
      booted.on 'hull.auth.complete', _.bind(loginHelpers.login, undefined,  appParts.app.sandbox.data.api.model, appParts.app.core.mediator)
      booted.on 'hull.auth.logout', _.bind(loginHelpers.logout, undefined, appParts.app.sandbox.data.api.model, appParts.app.core.mediator)
    ,(e)->
      console.error('Unable to start Aura app:', e)
      appParts.app.stop()
    booted
  failure: (error)->
    console.error(error.message)
    error
