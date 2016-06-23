{Range} = require('atom')
path = require 'path'
child_process = require('child_process')
minimatch = require('minimatch')

Helpers = module.exports =
  messageKey: (message) ->
    (message.text or message.html) + '$' + message.type + '$' + (message.class or '') + '$' + (message.name or '') + '$' + message.filePath + '$' + (if message.range then message.range.start.column + ':' + message.range.start.row + ':' + message.range.end.column + ':' + message.range.end.row else '')
  error: (e) ->
    atom.notifications.addError(e.toString(), {detail: e.stack or '', dismissable: true})
  shouldTriggerLinter: (linter, onChange, scopes) ->
    # Trigger lint-on-Fly linters on both events but on-save linters only on save
    # Because we want to trigger onFly linters on save when the
    # user has disabled lintOnFly from config
    return false if onChange and not linter.lintOnFly
    return false unless scopes.some (entry) -> entry in linter.grammarScopes
    return true
  requestUpdateFrame: (callback) ->
    setTimeout(callback, 100)
  debounce: (callback, delay) ->
    timeout = null
    return (arg) ->
      clearTimeout(timeout)
      timeout = setTimeout(() =>
        callback.call(this, arg)
      , delay)
  isPathIgnored: (filePath) ->
    repo = null
    for projectPath, i in atom.project.getPaths()
      if filePath.indexOf(projectPath + path.sep) is 0
        repo = atom.project.getRepositories()[i]
        break
    return true if repo and repo.isProjectAtRoot() and repo.isPathIgnored(filePath)
    return minimatch(filePath, atom.config.get('linter.ignoreMatchedFiles'))
