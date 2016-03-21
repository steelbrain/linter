'use babel'

/* @flow */

import minimatch from 'minimatch'
import type { Linter$Regular, Linter$Message } from './types'

export function showError(e: Error) {
  atom.notifications.addError(`[Linter] ${e.message}`, {
    detail: e.stack,
    dismissable: true
  })
}

export function shouldTriggerLinter(
  linter: Linter$Regular,
  wasTriggeredOnChange: boolean,
  scopes: Array<string>
): boolean {
  if (wasTriggeredOnChange && !linter.lintOnFly) {
    return false
  }
  return scopes.some(function(scope) {
    return linter.grammarScopes.indexOf(scope) !== -1
  })
}

export function isPathIgnored(filePath: string, ignoredGlob: string): boolean {
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

export function messageKey(message: Linter$Message): string {
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

export function fillMessage(message: Linter$Message, linterName: ?string) {
  message.name = message.name || linterName || null
  message.key = messageKey(message)
  if (!message.severity) {
    message.severity = message.type === 'Warning' || message.type === 'warning' ? 'warning' :
                       message.type === 'Info' || message.type === 'info' ? 'info' : 'error'
  }
}
