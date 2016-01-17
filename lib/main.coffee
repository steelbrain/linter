{Disposable} = require('atom')
module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint As You Type'
      description: 'Lint files while typing, without the need to save'
      type: 'boolean'
      default: true
      order: 1
    lintOnFlyInterval:
      title: 'Lint As You Type Interval'
      description: 'Interval at which providers are triggered as you type (in ms)'
      type: 'integer'
      default: 300
      order: 1

    ignoreGlob:
      title: 'Ignore files matching this Glob'
      type: 'string'
      default: '{\,/}**{\,/}*.min.{js,css}'
      order: 2

  activate: (@state) ->
    LinterPlus = require('./linter.coffee')
    @instance = new LinterPlus state

  serialize: ->
    @state

  consumeLinter: (linters) ->
    unless linters instanceof Array
      linters = [ linters ]

    for linter in linters
      @instance.addLinter(linter)

    new Disposable =>
      for linter in linters
        @instance.deleteLinter(linter)

  consumeUI: (UIs) ->
    unless UIs instanceof Array
      UIs = [ UIs ]
    for UI in UIs
      @instance.addUI(UI)

    new Disposable =>
      for UI in UIs
        @instance.deleteUI(UI)

  provideLinter: ->
    @instance

  provideIndie: ->
    @instance?.indieLinters

  deactivate: ->
    @instance?.deactivate()
