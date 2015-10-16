LinterRegistry = require('../lib/linter-registry')
EditorLinter = require('../lib/editor-linter')
Validators = require('../lib/validate')

module.exports =
  wait: (timeout) ->
    return new Promise (resolve) ->
      setTimeout(resolve, timeout)
  getLinter: ->
    return {grammarScopes: ['*'], lintOnFly: false, scope: 'project', lint: -> }
  getMessage: (type, filePath, range) ->
    message = {type, text: 'Some Message', filePath, range}
    Validators.messages([message], {name: 'Some Linter'})
    return message
  getLinterRegistry: ->
    linterRegistry = new LinterRegistry
    editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
    linter = {
      grammarScopes: ['*']
      lintOnFly: false
      scope: 'project'
      lint: -> return [{type: 'Error', text: 'Something'}]
    }
    linterRegistry.addLinter(linter)
    return {linterRegistry, editorLinter, linter}
  trigger: (el, name) ->
    event = document.createEvent('HTMLEvents')
    event.initEvent(name, true, false)
    el.dispatchEvent(event)
