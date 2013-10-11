define ['lib/client/datasource', 'underscore', 'string'], (Datasource, _)->
  module =
    datasourceModel: Datasource

    getDatasourceErrorHandler: (name, scope)->
      handler = scope["on#{_.string.capitalize(_.string.camelize(name))}Error"]
      handler = module.defaultErrorHandler unless _.isFunction(handler)
      _.bind(handler, scope)

    defaultErrorHandler: (datasourceName, err)->
      console.log "An error occurred with datasource #{datasourceName}", err
    
    # Adds datasources to the instance of the component
    addDatasources: (datasources)->
      @datasources ?= {}
      _.each datasources, (ds, i)=>
        ds = _.bind ds, @ if _.isFunction ds
        ds = new module.datasourceModel(ds, @api) unless ds instanceof module.datasourceModel
        @datasources[i] = ds
    
    # Fetches all the datasources for the instance of the component
    fetchDatasources: ()->
      @data ?= {}
      promiseArray  = _.map @datasources, (ds, k)=>
        ds.parse(_.extend({}, @, @options || {}))
        ds.fetch().then (res)=>
          @data[k] = if res.toJSON then res.toJSON() else res
        , (err)=>
          handler = module.getDatasourceErrorHandler(k, @)
          handler(k, err)
      @sandbox.data.when(promiseArray...)

    # Registers hooks and creates default datasources
    initialize: (app)->
      default_datasources =
        me: new module.datasourceModel app.core.data.api.model('me')
        app: new module.datasourceModel app.core.data.api.model('app')
        org: new module.datasourceModel app.core.data.api.model('org')

      app.components.before 'initialize', (options)->
        datasources = _.extend {}, default_datasources, @datasources, options.datasources
        module.addDatasources.call(@, datasources)

      app.components.before 'render', module.fetchDatasources

  module
