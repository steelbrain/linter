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

    ignoredMessageTypes:
      description: 'Comma separated list of message types to completely ignore'
      type: 'array'
      default: []
      items:
        type: 'string'
      order: 2
    ignoreVCSIgnoredFiles:
      title: 'Do Not Lint Files Ignored by VCS'
      description: 'E.g., ignore files specified in .gitignore'
      type: 'boolean'
      default: true
      order: 2
    ignoreMatchedFiles:
      title: 'Do Not Lint Files that match this Glob'
      type: 'string'
      default: '{\,/}**{\,/}*.min.{js,css}'
      order: 2

    errorPanelHeight:
      title: 'Error Panel Height'
      description: 'Height of the error panel (in px)'
      type: 'number'
      default: 150
      order: 4
    alwaysTakeMinimumSpace:
      title: 'Automatically Reduce Error Panel Height'
      description: 'Reduce panel height when it exceeds the height of the error list'
      type: 'boolean'
      default: true
      order: 4

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
