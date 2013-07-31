define ['underscore', 'lib/utils/promises', 'backbone', './sync', './cache'], (_, promises, Backbone, sync, cache)->
  Backbone.Model.extend
    sync: sync
    url: ->
      @get('id') || @_alias || @collection?.url
    set: (resp, options)->
      original = Backbone.Model.prototype.set
      dfd = promises.deferred()
      deferreds = []
      _.each resp, (value, prop)->
        if value?.id and value?.type and cache.has(value.id)
          modelDfd = cache.get value.id
          deferreds.push(modelDfd)
          modelDfd.then (obj)->
            resp[prop] = obj
      promises.when.apply(undefined, deferreds).then ()=>
        original.call @, resp, options
    toJSON: ()->
      json = Backbone.Model.prototype.toJSON.apply(@, arguments)
      _.each json, (value, prop)->
        if (value instanceof Backbone.Model)
          json[prop] = value.toJSON()
        return if (!_.isArray(value))
        _.each value, (elt, i)->
          json[value][i] = elt.toJSON() if elt instanceof Backbone.Model
      json

