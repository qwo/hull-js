define ['lib/client/component/component', 'underscore', 'lib/client/component/context'], (HullComponentModule, _, Context)->
  (app)->
    _invokeBeforeRender = (data, ctx)->
      dfd = app.core.data.deferred()
      @invokeWithCallbacks('beforeRender', ctx.build(), ctx.errors()).then (_data)=>
        data = _.extend({}, @data, _data || ctx.build(), data)
        dfd.resolve data
      , (err)->
        console.error(err)
        dfd.reject err
      dfd.promise()

    class HullRactive
      options: {}

      #
      # Ractive-specific properties
      #
      events: {} # Hull events, eg hull.auth.login
      helpers: {}
      actions: {} # Ractive events, eg <div on-click="doSomething">...</div>
      decorators: {}
      partials: {}
      computed: {}

      #
      # User methods
      #
      setupObservers: ->
      initialize: ->

      constructor: (options)->
        @ref = options.ref
        @api = @sandbox.data.api
        @refresh ?= _.throttle((-> @invokeWithCallbacks 'render' ), 200)
        @componentName = options.name

        options[k] ?= v for k, v of @options

        unless @className?
          @className = "hull-component"
          @className += " hull-#{@namespace}" if @namespace?

        @cid = _.uniqueId('view')
        @el = options.el
        @$el = $ @el
        @ractive = @setupRactive(@$el, "main")

#
        # Data Helpers
        #
        @getData = _.bind(@ractive.get, @ractive)
        @setData = _.bind(@ractive.set, @ractive)
        @observeData = _.bind(@ractive.observe, @ractive)
        @incData = (p, v = 1)=>
          @ractive.add p, v
        @decData = (p, v = 1)=>
          @ractive.subtract p, v

        @invokeWithCallbacks('initialize', options).then _.bind(->
          @setupObservers()
          @invokeWithCallbacks 'render'
          @sandbox.on('hull.settings.update', (conf)=> @sandbox.config.services = conf)
        , @), (err)->
          console.warn('WARNING', err)
          # Already displays a log in Aura and is caught above

      authServices: ()->
        @sandbox.util._.reject @sandbox.util._.keys(@sandbox.config.services.auth || {}), (service)-> service == 'hull'

      beforeRender: (data)-> data

      renderError: ->

      log: (msg)=>
        if @options.debug
          console.warn(@options.name, ":", @options.id, msg)
        else
          console.warn("[DEBUG] #{@options.name}", msg, @)

      buildContext: (ctx)=>
        @_renderCount ?= 0
        ctx.add 'options', @options
        ctx.add 'loggedIn', @loggedIn()
        ctx.add 'isAdmin', @sandbox.isAdmin()
        ctx.add 'debug', @sandbox.config.debug
        ctx.add 'renderCount', ++@_renderCount
        ctx

      loggedIn: =>
        return false unless @sandbox.data.api.model('me').get('id')?
        identities = {}
        me = @sandbox.data.api.model('me')
        _.map me.get("identities"), (i)->
          identities[i.provider] = i
        identities.email ?= {} if me.get('main_identity') == 'email'
        identities

      afterRender: (data)=> data

      render: (tpl, data)=>
        __ctx = new Context()
        @invokeWithCallbacks('buildContext', __ctx).then =>
          _invokeBeforeRender.call(@, data, __ctx).then (data)=>
            @invokeWithCallbacks 'doRender', tpl, data
            _.defer(=> @afterRender.call(@, data))
            _.defer(=> @sandbox.start(@$el, { reset: true }))
            @emitLifecycleEvent('render')
          , (err)=>
            console.error(err.message)
            @renderError(err)
      emitLifecycleEvent: (name)->
        @sandbox.emit("hull.#{@componentName.replace('/','.')}.#{name}",{cid:@cid})

      setupRactive: (node, template)->
        node.addClass @className
        _ = @sandbox.util._
        bindReduction = (memo, val, key)->
          memo[key] = _.bind val, self
          memo
        @actions = _.reduce @actions, bindReduction, {}
        @helpers = _.reduce @helpers, bindReduction, {}
        @decorators = _.reduce @decorators, bindReduction, {}

        ractive = new Ractive
          el: node
          template: RactiveTemplates[this.componentName+"/"+template]
          decorators: @decorators
          data:
            helpers: @helpers
            partials: @partials
          computed: @computed
        ractive.on @actions
        ractive
      doRender: (template, data)->
        @ractive.set data

    initialize: (app)->
      app.components.addType("Ractive", HullRactive.prototype)
