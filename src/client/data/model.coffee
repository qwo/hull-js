define ['underscore', 'backbone', './sync'], (_, Backbone, sync)->
  Base = Backbone.Model.extend
    sync: sync

  RawModel = Base.extend
    url: ->
      @_id || @id

  Model = Base.extend
    url: ->
      if (@id || @_id)
        url = @_id || @id
      else
        url = @collection?.url
      url

  return
    Raw: RawModel
    Model: Model
