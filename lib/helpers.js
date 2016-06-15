'use babel'

/* @flow */

import { Disposable, Range, Point } from 'atom'
import minimatch from 'minimatch'
import type { Linter, Message } from './types'

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

export function messageKey(message: Message) {
  return [
    `$LINTER:${message.linterName}`,
    `$LOCATION:${message.location.file}$${message.location.position.start.row}$${message.location.position.start.column}$${message.location.position.end.row}$${message.location.position.end.column}`,
    message.source ? `$SOURCE:${message.source.file}$${message.source.position.start.row}$${message.source.position.start.column}$${message.source.position.end.row}$${message.source.position.end.column}` : '$SOURCE:null',
    `$EXCERPT:${message.excerpt}`,
    `$SEVERITY:${message.severity}`,
    message.reference ? `$REFERENCE:${message.reference}` : '$REFERENCE:null',
    message.description && message.description.length ? `$DESCRIPTION:${message.description.join('')}` : '$DESCRIPTION:null',
  ].join('')
}

export function normalizeMessages(linterName: string, messages: Array<Message>) {
  for (let i = 0, length = messages.length, message; i < length; ++i) {
    message = messages[i]
    if (Array.isArray(message.location.position)) {
      message.location.position = Range.fromObject(message.location.position)
    }
    if (message.source && Array.isArray(message.source.position)) {
      message.source.position = Point.fromObject(message.source.position)
    }
    if (message.solutions && message.solutions.length) {
      for (let j = 0, _length = message.solutions.length, solution; j < _length; j++) {
        solution = message.solutions[j]
        if (Array.isArray(solution.position)) {
          solution.position = Range.fromObject(solution.position)
        }
      }
    }
    message.linterName = linterName
    message.key = messageKey(message)
  }
}

export const $activated: Symbol = Symbol('Linter activation status')
export const $requestLatest: Symbol = Symbol('Linter latest request')
export const $requestLastReceived: Symbol = Symbol('Linter last received request')
