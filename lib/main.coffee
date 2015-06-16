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
    @instance = new (require './linter-plus.coffee')

    legacy = require('./legacy.coffee')
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implementation = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        linter = legacy(require "#{atomPackage.path}/lib/#{implementation}")
        @consumeLinter(linter)

  consumeLinter: (linter) ->
    if linter instanceof Array
      for singleLinter of linter
        @consumeLinter(singleLinter)
    else
      if @_validateLinter(linter)
        @instance.linters.push linter

  consumeStatusBar: (statusBar) ->
    @instance.views.attachBottom(statusBar)

  provideLinter: ->
    @Linter

  deactivate: ->
    @instance?.deactivate()

  _validateLinter: (linter) ->
    if linter.grammarScopes instanceof Array and typeof linter.lint is 'function'
      true
    else
      err = new Error("Invalid Linter Provided")
      atom.notifications.addError err.message, {detail: err.stack}
      false