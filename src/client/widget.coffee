define ['underscore', 'backbone', 'lib/utils/promises', 'lib/hullbase', 'lib/client/data/objectResolver', 'lib/client/data/urlMapper', 'lib/client/widget/context'], (_, Backbone, promises, base, ObjectResolver, urlMapper, Context)->
  (app)->
    debug = false

    slice = Array.prototype.slice

    decamelize = (camelCase)->
      camelCase.replace(/([A-Z])/g, '_' + '$1').toLowerCase()

    default_datasources = {}

    actionHandler = (e)->
      try
        source  = $(e.currentTarget)
        action  = source.data("hull-action")
        fn = @actions[action] || @["#{action}Action"]
        fn = @[fn] if _.isString(fn)
        unless _.isFunction(fn)
          throw new Error("Can't find action #{action} on this Widget")
        data = {}
        for k,v of source.data()
          do ->
            key = k.replace(/^hull/, "")
            key = key.charAt(0).toLowerCase() + key.slice(1)
            data[key] = v
        fn.call(@, e, { el: source, data: data })
      catch err
        console.error("Error in action handler: ", action, err.message, err)
      finally
        e.stopPropagation()
        e.stopImmediatePropagation()


    class HullWidget extends Backbone.View
      actions: {}

      templates: []

      initialize: ->

      isInitialized: false

      constructor: (options)->
        @ref          = options.ref
        @datasources  = _.extend {}, @datasources, options.datasources
        @refresh     ?= _.throttle(@render, 200)

        for k, v of @options
          options[k] ||= v

        try
          @events = if _.isFunction(@events) then @events() else @events
          @events ?= {}
          @events["click [data-hull-action]"] = _.bind actionHandler,@

          # Building actions hash
          @actions = if _.isFunction(@actions) then @actions() else @actions
          @actions ?= {}
          @actions.login ?= (e, params)=> @sandbox.login(params.data.provider, params.data)
          @actions.logout ?= => @sandbox.logout()

          unless @className?
            @className = "hull-widget"
            @className += " hull-#{@namespace}" if @namespace?

          _.each @datasources, (ds, i)=>
            ds = _.bind ds, @ if _.isFunction ds
            @datasources[i] = ds

          @sandbox.on(refreshOn, (=> @refresh()), @) for refreshOn in (@refreshEvents || [])
        catch e
          console.error("Error loading HullWidget", e.message)
        sb = @sandbox
        getId = ()->
          return @id if @id
          return sb.util.entity.encode(@uid) if @uid
          sb.config.entity_id
        options.id = getId.call(options)
        Backbone.View.prototype.constructor.apply(@, arguments)
        @mainRefresh = => @refresh()
        @render()

      renderTemplate: (tpl, data)=>
        _tpl = @_templates?[tpl]
        if _tpl
          _tpl(data || @)
        else
          "Cannot find template '#{tpl}'"

      beforeRender: (data)-> data

      renderError: ->

      log: (msg)=>
        if @options.debug
          console.warn(@options.name, ":", @options.id, msg)
        else
          console.warn("[DEBUG] #{@options.name}", msg, @)

      buildContext: =>
        @_renderCount ?= 0
        ctx = new Context()
        ctx.add 'options', @options
        ctx.add 'loggedIn', @loggedIn()
        ctx.add 'isAdmin', @sandbox.isAdmin
        ctx.add 'debug', @sandbox.config.debug
        ctx.add 'renderCount', ++@_renderCount
        _.each default_datasources, (ds, k)->
          ctx.add k, ds

        dfd = @sandbox.data.deferred()
        datasourceErrors = {}
        try
          keys = _.keys(@datasources)
          promiseArray  = _.map keys, (k)=>
            ds = @datasources[k]
            uri = urlMapper(ds, _.extend({}, @, @options || {}))
            handler = @["on#{_.string.capitalize(_.string.camelize(k))}Error"]
            ctx.addDatasource(k, ObjectResolver.get(uri), handler)
          widgetDeferred = promises.when.apply(undefined, promiseArray)
          templateDeferred = @sandbox.template.load(@templates, @ref)
          templateDeferred.done (tpls)=>
            @_templates     = tpls
          readyDfd = promises.when(widgetDeferred, templateDeferred)
          readyDfd.fail (err)=>
            console.error("Error in Building Render Context", err.message, err)
            @renderError.call(@, err.message, err)
            dfd.reject err
          readyDfd.done ()->
            dfd.resolve ctx

        catch e
          console.error("Caught error in buildContext", e.message, e)
          dfd.reject(e)
        dfd.promise()

      loggedIn: =>
        me = default_datasources.me
        return false unless (me && me.get('id'))
        identities = {}
        me.get("identities").map (i)-> identities[i.provider] = i
        identities

      getTemplate: (tpl, data)=>
        tpl || @template || @templates[0]

      doRender: (tpl, data)=>
        tplName = @getTemplate(tpl, data)
        ret = @renderTemplate(tplName, data)
        @$el.addClass(this.className)
        ret = "<!-- START #{tplName} RenderCount: #{@_renderCount} -->#{ret}<!-- END #{tplName}-->" if debug
        @$el.html(ret)
        return @

      afterRender: (data)=> data

      # Build render context from datasources
      # Call beforeRender
      # doRender
      # afterRender
      # Start nested widgets...
      render: (tpl, data)=>
        ctxPromise = @buildContext.call(@)
        ctxPromise.fail (err)->
          console.error("Error fetching Datasources ", err.message, err)
        ctxPromise.then (ctx)=>
          try
            beforeCtx = @beforeRender.call(@, ctx.build(), ctx.errors())
            beforeRendering = promises.when(beforeCtx)
            beforeRendering.done (dataAfterBefore)=>
              #FIXME SRSLY need some clarification
              @data = data = _.extend(dataAfterBefore || ctx.build(), data)
              jsonCtx = {}
              _.each data, (ds, k)->
                ds = ds.toJSON() if ds and _.isFunction(ds.toJSON)
                jsonCtx[k] = ds
              _.each data, (ds)=>
                #TODO This can be enhanced
                if ds and _.isFunction(ds.on)
                  ds.on 'change', @mainRefresh
              @doRender(tpl, jsonCtx)
              _.defer(@afterRender.bind(@, jsonCtx))
              _.defer((-> @sandbox.start(@$el)).bind(@))
              @isInitialized = true;

            beforeRendering.fail (err)=>
              console.error("Error in beforeRender", err.message, err)
              @renderError.call(@, err)
          catch err
            console.error("Error in beforeRender", err.message, err)
            @renderError.call(@, err)

      trackingData: {}

      track: (name, data = {}) ->
        defaultData = _.result(this, 'trackingData')
        defaultData = if _.isObject(defaultData) then defaultData else {}
        data = _.extend { id: @id, widget: @options.name }, defaultData, data
        @sandbox.track(name, data)

    (auraApp)->
      debug = auraApp.config.debug
      auraApp.core.registerWidgetType("Hull", HullWidget.prototype)
      me = ObjectResolver.get 'me'
      app = ObjectResolver.get 'app'
      org = ObjectResolver.get 'org'
      promises.when(me, app, org).then (me, app, org)->
        base.me = default_datasources.me = me
        base.app = default_datasources.app = app
        base.org = default_datasources.org = org
