/* @flow */

import arrayUnique from 'lodash/uniq'
import { Disposable, Range, Point } from 'atom'
import type { TextEditor } from 'atom'
import type { Linter, Message } from './types'

export const $version = '__$sb_linter_version'
export const $activated = '__$sb_linter_activated'
export const $requestLatest = '__$sb_linter_request_latest'
export const $requestLastReceived = '__$sb_linter_request_last_received'

export function shouldTriggerLinter(linter: Linter, wasTriggeredOnChange: boolean, scopes: Array<string>): boolean {
  if (wasTriggeredOnChange && !linter.lintsOnChange) {
    return false
  }
  return scopes.some(function(scope) {
    return linter.grammarScopes.includes(scope)
  })
}

export function getEditorCursorScopes(textEditor: TextEditor): Array<string> {
  return arrayUnique(
    textEditor.getCursors().reduce((scopes, cursor) => scopes.concat(cursor.getScopeDescriptor().getScopesArray()), ['*']),
  )
}

let minimatch
export function isPathIgnored(filePath: ?string, ignoredGlob: string, ignoredVCS: boolean): boolean {
  if (!filePath) {
    return true
  }

  if (ignoredVCS) {
    let repository = null
    const projectPaths = atom.project.getPaths()
    for (let i = 0, { length } = projectPaths; i < length; ++i) {
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
  const normalizedFilePath = process.platform === 'win32' ? filePath.replace(/\\/g, '/') : filePath
  if (!minimatch) {
    minimatch = require('minimatch')
  }
  return minimatch(normalizedFilePath, ignoredGlob)
}

export function subscriptiveObserve(object: Object, eventName: string, callback: Function): Disposable {
  let subscription = null
  const eventSubscription = object.observe(eventName, function(props) {
    if (subscription) {
      subscription.dispose()
    }
    subscription = callback.call(this, props)
  })

  return new Disposable(function() {
    eventSubscription.dispose()
    if (subscription) {
      subscription.dispose()
    }
  })
}

export function messageKey(message: Message) {
  const { reference } = message
  return [
    `$LINTER:${message.linterName}`,
    `$LOCATION:${message.location.file}$${message.location.position.start.row}$${message.location.position.start.column}$${
      message.location.position.end.row
    }$${message.location.position.end.column}`,
    reference
      ? `$REFERENCE:${reference.file}$${reference.position ? `${reference.position.row}$${reference.position.column}` : ''}`
      : '$REFERENCE:null',
    `$EXCERPT:${message.excerpt}`,
    `$SEVERITY:${message.severity}`,
    message.icon ? `$ICON:${message.icon}` : '$ICON:null',
    message.url ? `$URL:${message.url}` : '$URL:null',
    typeof message.description === 'string' ? `$DESCRIPTION:${message.description}` : '$DESCRIPTION:null',
  ].join('')
}

export function normalizeMessages(linterName: string, messages: Array<Message>) {
  for (let i = 0, { length } = messages; i < length; ++i) {
    const message = messages[i]
    const { reference } = message
    if (Array.isArray(message.location.position)) {
      message.location.position = Range.fromObject(message.location.position)
    }
    if (reference && Array.isArray(reference.position)) {
      reference.position = Point.fromObject(reference.position)
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
    if (!message.linterName) {
      message.linterName = linterName
    }
    message.key = messageKey(message)
  }
}
