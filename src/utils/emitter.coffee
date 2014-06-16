define ['underscore', 'eventemitter'], (_, EventEmitter2)->

  methods =
    'on': (evt, fn)->
      @on evt, (args...)->
        evt = @event
        try
          throw new Error()
        catch e
          stack = e.stack.split('\n')
          stack.shift()
          stack = _.map stack, (s)->
            s.trim()
        fn.apply(@, args.concat({ eventName: evt, stack: stack.join('\n') }))
    'onAny': null
    'offAny': null
    'once': null
    'many': null
    'off': null
    'removeAllListeners': null
    'listeners': null
    'listenersAny': null
    'emit': null
    'setMaxListeners': null

  (debug)->
    _ee = new EventEmitter2
      wildcard: true
      delimiter: '.'
      newListener: false
      maxListeners: 100
    ee = {}
    for name, method of methods
      method = _ee[name] unless method and debug
      ee[name] = _.bind(method, _ee)
    ee
