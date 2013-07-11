define ['underscore', 'backbone', './sync'], (_, Backbone, sync)->
  Backbone.Model.extend
    sync: sync
    url: ->
      if (@id || @_id)
        url = @_id || @id
      else
        url = @collection?.url
      url

