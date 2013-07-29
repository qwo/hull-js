define ['underscore', 'lib/api', './model', './collection', './urlMapper'], (_, api, Model, Collection, urlMapper)->
  #
  # Helps managing the various definitions a widget datasource can take
  # Sets decent defaults, validates input, and sends requests to the API
  #
  class Datasource
    #
    # @param {String|Object|Function} A potentially partial definition of the datasource
    #
    constructor: (ds) ->
      _errDefinition  = new TypeError('Datasource is missing its definition. Cannot continue.')
      throw _errDefinition unless ds
      if _.isString(ds)
        ds =
          path: ds
          provider: 'hull'
      else if _.isObject(ds) && !_.isFunction(ds)
        throw _errDefinition unless ds.path
        ds.provider = ds.provider || 'hull'
      @def = ds

    #
    # Replaces the placeholders in the URI with actual data
    # @param {Object} bindings Key/Value pairs to replace the placeholders wih their values
    #
    parse:(bindings)->
      @def.path = urlMapper(@def.path, bindings) unless _.isFunction(@def)

    _fetching: null
    #
    # Send the requests.
    # If the definition of the datasource is a function,
    # this function is executed.aUseful for static datasources or second-order datasources
    #
    # @returns {mixed} May return an object, a Promise most likely or anything else
    #
    fetch: ()->
      if @_fetching
        return @_fetching
      dfd = $.Deferred()
      def = @def
      if _.isFunction(@def)
      #   ret = @def()
      #   if ret?.promise
      #     dfd = ret
      #   else
      #     dfd.resolve ret
      else
        # Dangerous. We can do it here because
        # we KNOW the API has already been configures before
        api(@def).then (apiObj)->
          apiObj.api(def).then (data)->
            if _.isArray(data)
              data = new Collection(data)
            else
              data = new Model(data)
            dfd.resolve(data)
      @_fetching =dfd.promise()
      @_fetching

  Datasource

