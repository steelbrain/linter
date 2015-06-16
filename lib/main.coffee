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
    @instance = new (require './linter-plus.coffee')

    legacy = require('./legacy.coffee')
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implementation = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        linter = legacy(require "#{atomPackage.path}/lib/#{implementation}")
        @consumeLinter(linter)

  consumeLinter: (linters) ->
    unless linters instanceof Array
      linters = [ linters ]
    for linter in linters
      if @_validateLinter(linter)
        @instance.linters.push linter
    new Disposable =>
      @instance.linters = @instance.linters.filter (item) =>
        unless item in linters
          if item.scope is 'project'
            @instance.messagesProject.delete(item)
          else
            @instance.eachLinter (editorLinter) -> editorLinter.messages.delete(item)
          false
        true
      @instance.views.render()
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