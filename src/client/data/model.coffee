# The class that will be instanciated for all the objects
# that will get into hull.
# Recursively serializes and deserializes objects for the properties
# that describe objects too.
define ['underscore', 'lib/utils/promises', 'backbone', './sync', './cache'], (_, promises, Backbone, sync, cache)->
  _isObjectDescription = (data)->
    data and data.id and data.type

  Model = Backbone.Model.extend
    sync: sync
    url: ->
      @get('id') || @_alias || @collection?.url
    set: (resp, options)->
      original = Backbone.Model.prototype.set
      dfd = promises.deferred()
      deferreds = []
      _.each resp, (value, prop)->
        #We don't describe properties which values are arrays
        #which elements describe objects
        #In other words: We don't describe ModelCollections (see List API)
        if value?.id and value?.type
          if cache.has(value.id)
            modelDfd = cache.get value.id
            deferreds.push modelDfd 
            modelDfd.then (obj)->
              resp[prop] = obj
          else
            promise = promises.deferred()
            model = new Model(value)
            cache.set(model.get('id'), promise.resolve(model))
      promises.when.apply(undefined, deferreds).then ()=>
        original.call @, resp, options
    toJSON: ()->
      json = Backbone.Model.prototype.toJSON.apply(@, arguments)
      _.each json, (value, prop)->
        if (value instanceof Model)
          json[prop] = value.toJSON()
        return if (!_.isArray(value))
        # That should be a Collection
        # If it is an array that contains models...
        _.each value, (elt, i)->
          json[value][i] = elt.toJSON() if elt instanceof Model
      json
  Model

