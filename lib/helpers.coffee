{Range} = require('atom')
path = require 'path'
child_process = require('child_process')

Helpers = module.exports =
  error: (e) ->
    atom.notifications.addError(e.toString(), {detail: e.stack or '', dismissable: true})
  shouldTriggerLinter: (linter, bufferModifying, onChange, scopes) ->
    # Trigger lint-on-Fly linters on both events but on-save linters only on save
    # Because we want to trigger onFly linters on save when the
    # user has disabled lintOnFly from config
    return false if onChange and not linter.lintOnFly
    return false unless scopes.some (entry) -> entry in linter.grammarScopes
    return false if linter.modifiesBuffer isnt bufferModifying
    return true
  requestUpdateFrame: (callback) ->
    setTimeout(callback, 100)
