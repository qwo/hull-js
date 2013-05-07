define ['backbone', 'components/Backbone_IdentityMap/backbone-identity-map'], ->

  #FIX These Dependencies are app-wide, not module-wide
  api = null
  deferred = null
  mediator = null

  slice = Array.prototype.slice

  keywords =
    me: null
    app: null
    org: null


  methodMap =
    'create': 'post'
    'update': 'put'
    'delete': 'delete'
    'read':   'get'

  sync = (method, model, options={})->
    url   = if _.isFunction(model.url) then model.url() else model.url
    verb  = methodMap[method]

    data = options.data
    if !data? && model && (method == 'create' || method == 'update' || method == 'patch')
      data = options.attrs || model.toJSON(options)

    dfd = api(url, verb, data)
    dfd.then(options.success)
    dfd.fail(options.error)
    dfd

  Model = Backbone.IdentityMap Backbone.Model.extend
    sync: sync
    initialize: ->
      @on 'change', ->
        args = slice.call(arguments)
        eventName = ("model.hull." + @_id + '.' + 'change')
        mediator.emit(eventName, { eventName: eventName, model: @, changes: args[1]?.changes })
    url: ->
      if (@id || @_id)
        url = @_id || @id
      else
        url = @collection?.url
      url

  Collection = Backbone.IdentityMap Backbone.Collection.extend
    model: Model
    sync: sync

  generateModel = (attrs) ->
    if attrs.id || attrs._id
      model = new Model(attrs)
    else
      model = new Model()

  setupModel = (attrs)->
    if keywords[attrs._id]
      model = generateModel({id:keywords[attrs._id]})
    else
      model = generateModel(attrs)
    dfd   = model.deferred = deferred()
    model._id = attrs._id
    modelId = model.id || model.get('id')
    if modelId
      model._fetched = true
      _id = model.get('_id')
      if _id && !keywords[_id]
        console.log('Setting URI', _id)
        keywords[_id] = model.get('id')
      dfd.resolve(model)
    else
      model._fetched = false
      model.fetch
        success: ->
          model._fetched = true
          _id = model.get('_id')
          if _id && !keywords._id
            console.log('Setting URI', _id)
            keywords[_id] = model.get('id')
          dfd.resolve(model)
        error:   ->
          dfd.fail(model)
    model

  createModel = (attrs)->
    if _.isString(attrs)
      uri = attrs
      attrs = { _id: uri }
      if keywords.hasOwnProperty uri
        attrs.id = keywords[uri]
      else
        keywords[uri] = null

    attrs._id = attrs.path unless attrs._id
    throw new Error('A model must have an identifier...') unless attrs?._id?
    setupModel(attrs)

  createCollection = (path)->
    collection = new Collection
    collection.on 'all', ->
      args = slice.call(arguments)
      eventName = ("collection." + @url(/\//g, ".") + '.' + args[0])
      mediator.emit(eventName, { eventName: eventName, collection: @, changes: args[1]?.changes })
    collection.url  = path
    dfd   = collection.deferred = deferred()
    if collection.models.length > 0
      collection._fetched = true
      dfd.resolve(collection)
    else
      collection._fetched = false
      collection.fetch
        success: ->
          collection._fetched = true
          dfd.resolve(collection)
        error:   ->
          dfd.fail(collection)
    collection


  return {
    createModel: createModel,
    createCollection: createCollection,
    initialize: (_api, _deferred, _mediator) ->
      api = _api
      deferred = _deferred
      mediator = _mediator
  }
