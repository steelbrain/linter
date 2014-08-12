findFile = require './util'

log = (args...) ->
  if atom.config.get 'linter.lintDebug'
    console.log args...

warn = (args...) ->
  if atom.config.get 'linter.lintDebug'
    console.warn args...

module.exports = {log, warn, findFile}
