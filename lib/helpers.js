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
  return scopes.some(function (scope) {
    return linter.grammarScopes.indexOf(scope) !== -1
  })
}

export function requestUpdateFrame(callback) {
  setTimeout(callback, 100)
}

export function debounce(callback, delay) {
  let timeout = null
  return function(arg) {
    clearTimeout(timeout)
    timeout = setTimeout(() => {
      callback.call(this, arg)
    }, delay)
  }
}

export function isPathIgnored(filePath, ignoredGlob) {
  const projectPaths = atom.project.getPaths()
  const projectPathsLength = projectPaths.length
  let   repository = null
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
