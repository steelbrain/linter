'use babel'

/* @flow */

import { Range, Disposable } from 'atom'
import minimatch from 'minimatch'
import type { Linter, Message } from './types'

export function showError(e: Error) {
  atom.notifications.addError(`[Linter] ${e.message}`, {
    detail: e.stack,
    dismissable: true
  })
}

export function shouldTriggerLinter(
  linter: Linter,
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

export function isPathIgnored(filePath: string, ignoredGlob: string, ignoredVCS: boolean): boolean {
  if (ignoredVCS) {
    let repository = null
    const projectPaths = atom.project.getPaths()
    for (let i = 0, length = projectPaths.length; i < length; ++i) {
      const projectPath = projectPaths[i]
      if (filePath.indexOf(projectPath) === 0) {
        repository = atom.project.getRepositories()[i]
        break
      }
    }
    if (repository && repository.isPathIgnored(filePath)) {
      return true
    }
  }
  return minimatch(filePath, ignoredGlob)
}

export function messageKey(message: Message): string {
  return (message.text || message.html) + '$' + message.type + '$' + (message.class || '') + '$' +
  (message.name || '') + '$' + message.filePath + '$' + (
    message.range ? (
      message.range.start.column + ':' + message.range.start.row + ':' +
        message.range.end.column + ':' + message.range.end.row
    ) : ''
  )
}

export function fillMessage(message: Message, linterName: ?string) {
  if (!message.name) {
    message.name = linterName || null
  }
  if (message.range && message.range.constructor.name === 'Array') {
    message.range = Range.fromObject(message.range)
  }
  message.key = messageKey(message)
  if (!message.severity) {
    message.severity = message.type === 'Warning' || message.type === 'warning' ? 'warning' :
                       message.type === 'Info' || message.type === 'info' ? 'info' : 'error'
  }
}

export function deferredSubscriptiveObserve(object: Object, eventName: string, callback: Function): Disposable {
  let subscription = null
  let eventSubscription = null
  setImmediate(function() {
    eventSubscription = object.observe(eventName, function(props) {
      if (subscription) {
        subscription.dispose()
      }
      subscription = callback.call(this, props)
    })
  })
  return new Disposable(function() {
    if (eventSubscription) {
      eventSubscription.dispose()
    }
    if (subscription) {
      subscription.dispose()
    }
  })
}

export const $activated: Symbol = Symbol('Linter activation status')
export const $requestLatest: Symbol = Symbol('Linter latest request')
export const $requestLastReceived: Symbol = Symbol('Linter last received request')
