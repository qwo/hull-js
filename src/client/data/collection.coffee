define ['backbone', './model', './sync'], (Backbone, Model, sync)->
  Backbone.Collection.extend
    model: Model
    sync: sync

