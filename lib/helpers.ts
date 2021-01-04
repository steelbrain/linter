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
  return scopes.some(function (scope) {
    return linter.grammarScopes.includes(scope)
  })
}

export function getEditorCursorScopes(textEditor: TextEditor): Array<string> {
  return arrayUnique(
    textEditor.getCursors().reduce((scopes, cursor) => scopes.concat(cursor.getScopeDescriptor().getScopesArray()), ['*']),
  )
}

let minimatch
export function isPathIgnored(filePath: string | null | undefined, ignoredGlob: string, ignoredVCS: boolean): boolean {
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

export function subscriptiveObserve(
  object: Record<string, any>,
  eventName: string,
  callback: (...args: Array<any>) => any,
): Disposable {
  let subscription = null
  const eventSubscription = object.observe(eventName, function (props) {
    if (subscription) {
      subscription.dispose()
    }
    subscription = callback.call(this, props)
  })

  return new Disposable(function () {
    eventSubscription.dispose()
    if (subscription) {
      subscription.dispose()
    }
  })
}

export function updateMessageKey(message: Message) {
  const { reference, location } = message
  message.key = [
    `$LINTER:${message.linterName}`,
    `$LOCATION:${location.file}$${location.position.start.row}$${location.position.start.column}$${location.position.end.row}$${location.position.end.column}`,
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
    updateMessageKey(message)
  }
}

// update the key of the given messages
export function updateKeys(messages: Array<Message>) {
  messages.forEach(m => {
    updateMessageKey(m)
  })
}

// create a map from keys to messages
export function createKeyMessageMap(messages: Array<Message>): Map<string, Message> {
  const keyMessageMap = new Map()
  for (let i = 0, { length } = messages; i < length; ++i) {
    const message = messages[i]
    keyMessageMap.set(message.key, message)
  }
  return keyMessageMap
}

interface FlaggedMessages {
  oldKept: Array<Message>
  oldRemoved: Array<Message>
  newAdded: Array<Message>
}

// This fast function returns the new messages and old messages by comparing their key against the cache.
// This prevents re-rendering the already rendered messages
export function flagMessages(inputs: Array<Message>, oldMessages: Array<Message>): FlaggedMessages | null {
  // inputs check
  if (inputs === undefined || oldMessages === undefined) {
    return null
  }

  // All the messages of the linter are new, no need to diff
  // tag the messages for adding and save them to linter's cache
  if (!oldMessages.length) {
    // NOTE: No need to add .key here because normalizeMessages already does that
    return { oldKept: [], oldRemoved: [], newAdded: inputs }
  }

  // The linter has no messages anymore
  // tag all of its messages from cache for removal and empty the cache
  if (!inputs.length) {
    return { oldKept: [], oldRemoved: oldMessages, newAdded: [] }
  }

  // In all the other situations:
  // perform diff checking between the linter's new messages and its cache

  // create a map from keys to oldMessages
  const cache = createKeyMessageMap(oldMessages)

  // Find old kept and new added
  const newAdded: Set<Message> = new Set()
  const oldKept: Map<string, Message> = new Map()
  for (let iInput = 0, len = inputs.length; iInput < len; iInput++) {
    const input = inputs[iInput]
    if (cache.has(input.key)) {
      oldKept.set(input.key, input)
    } else {
      newAdded.add(input)
    }
  }

  // Find old removed
  const cacheKeys = Array.from(cache.keys())
  const oldKeptKeys = Array.from(oldKept.keys())

  const oldRemovedKeys = cacheKeys.filter(x => !oldKeptKeys.includes(x))

  const oldRemoved = new Set()
  for (let iRemoved = 0, RemovedKeysLen = oldRemovedKeys.length; iRemoved < RemovedKeysLen; iRemoved++) {
    oldRemoved.add(cache.get(oldRemovedKeys[iRemoved]))
  }

  return {
    oldKept: Array.from(oldKept.values()),
    oldRemoved: oldRemoved ? Array.from(oldRemoved) : [],
    newAdded: Array.from(newAdded),
  }
}

// fast mergeArray function
// https://uilicious.com/blog/javascript-array-push-is-945x-faster-than-array-concat/
export function mergeArray(arr1: Array<any>, arr2: Array<any>) {
  if (!arr2.length) {
    return
  }
  Array.prototype.push.apply(arr1, arr2)
}
