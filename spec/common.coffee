LinterRegistry = require('../lib/linter-registry')
EditorLinter = require('../lib/editor-linter')

module.exports =
  getLinter: ->
    return {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'project', lint: -> }
  getMessage: (type, filePath) ->
    return {type, text: "Some Message", filePath}
  getLinterRegistry: ->
    linterRegistry = new LinterRegistry
    editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
    linter = {
      grammarScopes: ['*']
      lintOnFly: false
      modifiesBuffer: false
      scope: 'project'
      lint: -> return [{type: "Error", text: "Something"}]
    }
    linterRegistry.addLinter(linter)
    return {linterRegistry, editorLinter, linter}
