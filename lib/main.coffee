{Disposable} = require('atom')
module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean'
      default: true
    showErrorInline:
      title: "Show Inline Tooltips"
      descriptions: "Show inline tooltips for errors"
      type: 'boolean'
      default: true

  activate: ->
    LinterPlus = require('./linter-plus.coffee')
    @instance = new LinterPlus()

    legacy = require('./legacy.coffee')
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implementation = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        linter = legacy(require("#{atomPackage.path}/lib/#{implementation}"))
        @consumeLinter(linter)

  consumeLinter: (linters) ->
    unless linters instanceof Array
      linters = [ linters ]

    for linter in linters
      try
        if @_validateLinter(linter)
          @instance.linters.add(linter)
      catch err
        atom.notifications.addError("Invalid Linter: #{err.message}", {
          detail: err.stack,
          dismissable: true
        })

    new Disposable( =>
      for linter in linters
        return unless @instance.linters.has(linter)
        if linter.scope is 'project'
          @instance.messagesProject.delete(linter)
        else
          @instance.eachEditorLinter((editorLinter) ->
            editorLinter.deleteMessages(linter)
          )
        @instance.linters.delete(linter)

      @instance.views.render()
    )

  consumeStatusBar: (statusBar) ->
    @instance.views.attachBottom(statusBar)

  provideLinter: ->
    @Linter

  deactivate: ->
    @instance?.deactivate()

  _validateLinter: (linter) ->
    unless linter.grammarScopes instanceof Array
      message = "grammarScopes is not an Array. (see console for more info)"
      console.warn(message)
      console.warn('grammarScopes', linter.grammarScopes)
      throw new Error(message)

    unless linter.lint?
      throw new Error("Missing linter.lint")

    if typeof linter.lint isnt 'function'
      throw new Error("linter.lint isn't a function")

    return true
