/* @flow */

import { Disposable, Range, Point } from 'atom'
import minimatch from 'minimatch'
import type { Linter, Message, MessageLegacy } from './types'

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
  const source = message.source
  return [
    `$LINTER:${message.linterName}`,
    `$LOCATION:${message.location.file}$${message.location.position.start.row}$${message.location.position.start.column}$${message.location.position.end.row}$${message.location.position.end.column}`,
    source ? `$SOURCE:${source.file}$${source.position ? `${source.position.start.row}$${source.position.start.column}$${source.position.end.row}$${source.position.end.column}` : ''}` : '$SOURCE:null',
    `$EXCERPT:${message.excerpt}`,
    `$SEVERITY:${message.severity}`,
    message.reference ? `$REFERENCE:${message.reference}` : '$REFERENCE:null',
  ].join('')
}

export function normalizeMessages(linterName: string, messages: Array<Message>) {
  for (let i = 0, length = messages.length; i < length; ++i) {
    const message = messages[i]
    const source = message.source
    if (Array.isArray(message.location.position)) {
      message.location.position = Range.fromObject(message.location.position)
    }
    if (source && Array.isArray(source.position)) {
      source.position = Point.fromObject(source.position)
    }
    if (message.solutions && message.solutions.length) {
      for (let j = 0, _length = message.solutions.length, solution; j < _length; j++) {
        solution = message.solutions[j]
        if (Array.isArray(solution.position)) {
          solution.position = Range.fromObject(solution.position)
        }
      }
    }
    message.version = 2
    message.linterName = linterName
    message.key = messageKey(message)
  }
}

export function messageKeyLegacy(message: MessageLegacy): string {
  return [
    `$LINTER:${message.linterName}`,
    `$LOCATION:${message.filePath || ''}$${message.range ? `${message.range.start.row}$${message.range.start.column}$${message.range.end.row}$${message.range.end.column}` : ''}`,
    `$TEXT:${message.text || ''}`,
    `$HTML:${message.html || ''}`,
    `$SEVERITY:${message.severity}`,
    `$TYPE:${message.type}`,
    `$CLASS:${message.class || ''}`,
  ].join('')
}

export function normalizeMessagesLegacy(linterName: string, messages: Array<MessageLegacy>) {
  for (let i = 0, length = messages.length; i < length; ++i) {
    const message = messages[i]
    const fix = message.fix
    message.version = 1
    if (message.range && message.range.constructor.name === 'Array') {
      message.range = Range.fromObject(message.range)
    }
    if (fix && fix.range.constructor.name === 'Array') {
      fix.range = Range.fromObject(fix.range)
    }
    if (!message.severity) {
      const type = message.type.toLowerCase()
      if (type === 'warning') {
        message.severity = type
      } else if (type === 'info') {
        message.severity = type
      } else {
        message.severity = 'error'
      }
    }
    message.linterName = linterName
    message.key = messageKeyLegacy(message)
  }
}

export const $version = '__$sb_linter_version'
export const $activated = '__$sb_linter_activated'
export const $requestLatest = '__$sb_linter_request_latest'
export const $requestLastReceived = '__$sb_linter_request_last_received'
