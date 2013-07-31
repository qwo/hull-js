define ['underscore', 'lib/api', './model', './collection', './urlMapper'], (_, api, Model, Collection, urlMapper)->
  #
  # The one and only way to manage raw data coming from the API.
  # It 
  # * takes any kind of descriptor (string with placholders, object leterals),
  # * giv the urlMapper
  # lets the API do its job,
  #
  #
  class Datasource
    #
    # @param {String|Object|Function} A potentially partial definition of the datasource
    #
    constructor: (ds) ->
      _errDefinition  = new TypeError('Datasource is missing its definition. Cannot continue.')
      throw _errDefinition unless ds
      @def = ds

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
        api().then (apiObj)->
          apiObj.api(def).then (data)->
            if _.isArray(data)
              data = new Collection(data)
              data.url = def
            else
              data = new Model(data)
            dfd.resolve(data)
      @_fetching =dfd.promise()
      @_fetching

  Datasource

