define ['underscore', 'backbone', './sync'], (_, Backbone, sync)->
  Backbone.Model.extend
    sync: sync
    url: ->
      if @get('id')
        url = @get('id')
      else
        url = @_alias || @collection?.url
      url

