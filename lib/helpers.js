'use babel'

import minimatch from 'minimatch'

export function showError(e) {
  atom.notifications.addError(`[Linter] ${e.message}`, {
    detail: e.stack,
    dismissable: true
  })
}

export function shouldTriggerLinter(linter, wasTriggeredOnChange, scopes) {
  if (wasTriggeredOnChange && !linter.lintOnFly) {
    return false
  }
  return scopes.some(function(scope) {
    return linter.grammarScopes.indexOf(scope) !== -1
  })
}

export function isPathIgnored(filePath, ignoredGlob) {
  let repository = null
  const projectPaths = atom.project.getPaths()
  const projectPathsLength = projectPaths.length
  for (let i = 0; i < projectPathsLength; ++i) {
    const projectPath = projectPaths[i]
    if (filePath.indexOf(projectPath) === 0) {
      repository = atom.project.getRepositories()[i]
      break
    }
  }
  if (repository !== null && repository.isProjectAtRoot() && repository.isPathIgnored(filePath)) {
    return true
  }
  return minimatch(filePath, ignoredGlob)
}

export function messageKey(message) {
  return (message.text || message.html) + '$' + message.type + '$' + (message.class || '') + '$' +
  (message.name || '') + '$' + message.filePath + '$' + (
    message.range ? (
      message.range.constructor.name === 'Array' ?
      message.range[0][1] + ':' + message.range[0][0] + ':' + message.range[1][1] + ':' + message.range[1][0] :
      message.range.start.column + ':' + message.range.start.row + ':' + message.range.end.column + ':' +
      message.range.end.row
    ) : ''
  )
}
