define ['lib/utils/promises', 'jquery', 'underscore'], (promises, $, _)->

  # Handles the various priorities and locations of templates
  _getTemplateDefinition = (name, ref, widgetName)->
    path = "#{ref}/#{name}"
    tplName = [widgetName, name.replace(/^_/, '')].join("/")
    localTpl = $("script[data-hull-template='#{tplName}']")
    if localTpl.length
      parsed = localTpl.text()
    else if module.global.Hull.templates[tplName]
      parsed = module.global.Hull.templates["#{tplName}"]
    # # Meteor
    # else if module.global.Meteor? && module.global.Template?[tplName]?
    #   parsed = module.global.Template[tplName]
    # # Sprockets
    # else if module.global.HandlebarsTemplates? && module.global.HandlebarsTemplates?[tplName]?
    #   parsed = module.global.HandlebarsTemplates[tplName]
    else if module.global.Hull.templates._default?[tplName]
      parsed = module.global.Hull.templates._default[tplName]
    else
      return
    module.define path, parsed
    parsed


  load = (names=[], ref, format="hbs") ->
    undefinedTemplates = []
    names = [names] if _.isString(names)
    dfd   = promises.deferred()
    ret = {}
    widgetName = ref.replace('__widget__$', '').split('@')[0]
    for name in names
      # tplDef = _getTemplateDefinition name, ref, widgetName
      # if tplDef
      #   ret[name] = tplDef
      # else
        undefinedTemplates.push([name, "#{widgetName}/#{name}"])
    if undefinedTemplates.length > 0
      module.require(_.map(undefinedTemplates, (p) -> "text!widgets/" + p[1] + ".hbs"), ->
        res = Array.prototype.slice.call(arguments)
        for t,i in res
          name = undefinedTemplates[i][0]
          tplName = [widgetName, name].join("/")
          ret[name] = t
        dfd.resolve(ret)
      , (err)->
        console.error("Error loading templates", undefinedTemplates, err)
        dfd.reject(err))
    else
      dfd.resolve(ret)
    dfd.promise()

  module =
    global: window
    define: define
    require: require
    load: load


