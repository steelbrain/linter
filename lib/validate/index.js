/* @flow */

import { Range, Point } from 'atom'
import { showError } from './helpers'
import type { UI, Linter, Message, MessageLegacy, Indie } from '../types'

const VALID_SEVERITY = new Set(['error', 'warning', 'info'])

function validateUI(ui: UI): boolean {
  const messages = []

  if (ui && typeof ui === 'object') {
    if (typeof ui.name !== 'string') {
      messages.push('UI.name must be a string')
    }
    if (typeof ui.didBeginLinting !== 'function') {
      messages.push('UI.didBeginLinting must be a function')
    }
    if (typeof ui.didFinishLinting !== 'function') {
      messages.push('UI.didFinishLinting must be a function')
    }
    if (typeof ui.render !== 'function') {
      messages.push('UI.render must be a function')
    }
    if (typeof ui.dispose !== 'function') {
      messages.push('UI.dispose must be a function')
    }
  } else {
    messages.push('UI must be an object')
  }

  if (messages.length) {
    showError('Invalid UI received', `These issues were encountered while registering the UI named '${ui && ui.name ? ui.name : 'Unknown'}'`, messages)
    return false
  }

  return true
}

function validateLinter(linter: Linter, version: 1 | 2): boolean {
  const messages = []

  if (linter && typeof linter === 'object') {
    if (typeof linter.name !== 'string') {
      messages.push('Linter.name must be a string')
    }
    if (typeof linter.scope !== 'string' || (linter.scope !== 'file' && linter.scope !== 'project')) {
      messages.push("Linter.scope must be either 'file' or 'project'")
    }
    if (version === 1 && typeof linter.lintOnFly !== 'boolean') {
      messages.push('Linter.lintOnFly must be a boolean')
    } else if (version === 2 && typeof linter.lintsOnChange !== 'boolean') {
      messages.push('Linter.lintsOnChange must be a boolean')
    }
    if (!Array.isArray(linter.grammarScopes)) {
      messages.push('Linter.grammarScopes must be an Array')
    }
    if (typeof linter.lint !== 'function') {
      messages.push('Linter.lint must be a function')
    }
  } else {
    messages.push('Linter must be an object')
  }

  if (messages.length) {
    showError('Invalid Linter received', `These issues were encountered while registering a Linter named '${linter && linter.name ? linter.name : 'Unknown'}'`, messages)
    return false
  }

  return true
}

function validateIndie(indie: Indie): boolean {
  const messages = []

  if (indie && typeof indie === 'object') {
    if (typeof indie.name !== 'string') {
      messages.push('Indie.name must be a string')
    }
  } else {
    messages.push('Indie must be an object')
  }

  if (messages.length) {
    showError('Invalid Indie received', `These issues were encountered while registering an Indie Linter named '${indie && indie.name ? indie.name : 'Unknown'}'`, messages)
    return false
  }

  return true
}

function validateMessages(linterName: string, entries: Array<Message>): boolean {
  const messages = []

  if (Array.isArray(entries)) {
    let invalidURL = false
    let invalidIcon = false
    let invalidExcerpt = false
    let invalidLocation = false
    let invalidSeverity = false
    let invalidSolution = false
    let invalidReference = false
    let invalidDescription = false

    for (let i = 0, length = entries.length; i < length; ++i) {
      const message = entries[i]
      const reference = message.reference
      if (!invalidIcon && message.icon && typeof message.icon !== 'string') {
        invalidIcon = true
        messages.push('Message.icon must be a string')
      }
      if (!invalidLocation && (!message.location || typeof message.location !== 'object' || typeof message.location.file !== 'string' || typeof message.location.position !== 'object' || !message.location.position)) {
        invalidLocation = true
        messages.push('Message.location must be valid')
      } else if (!invalidLocation) {
        const range = Range.fromObject(message.location.position)
        if (Number.isNaN(range.start.row) || Number.isNaN(range.start.column) || Number.isNaN(range.end.row) || Number.isNaN(range.end.column)) {
          invalidLocation = true
          messages.push('Message.location.position should not contain NaN coordinates')
        }
      }
      if (!invalidSolution && message.solutions && !Array.isArray(message.solutions)) {
        invalidSolution = true
        messages.push('Message.solutions must be valid')
      }
      if (!invalidReference && reference && (typeof reference !== 'object' || typeof reference.file !== 'string' || typeof reference.position !== 'object' || !reference.position)) {
        invalidReference = true
        messages.push('Message.reference must be valid')
      } else if (!invalidReference && reference) {
        const position = Point.fromObject(reference.position)
        if (Number.isNaN(position.row) || Number.isNaN(position.column)) {
          invalidReference = true
          messages.push('Message.reference.position should not contain NaN coordinates')
        }
      }
      if (!invalidExcerpt && typeof message.excerpt !== 'string') {
        invalidExcerpt = true
        messages.push('Message.excerpt must be a string')
      }
      if (!invalidSeverity && !VALID_SEVERITY.has(message.severity)) {
        invalidSeverity = true
        messages.push("Message.severity must be 'error', 'warning' or 'info'")
      }
      if (!invalidURL && message.url && typeof message.url !== 'string') {
        invalidURL = true
        messages.push('Message.url must a string')
      }
      if (!invalidDescription && message.description && typeof message.description !== 'function' && typeof message.description !== 'string') {
        invalidDescription = true
        messages.push('Message.description must be a function or string')
      }
    }
  } else {
    messages.push('Linter Result must be an Array')
  }

  if (messages.length) {
    showError('Invalid Linter Result received', `These issues were encountered while processing messages from a linter named '${linterName}'`, messages)
    return false
  }

  return true
}

function validateMessagesLegacy(linterName: string, entries: Array<MessageLegacy>): boolean {
  const messages = []

  if (Array.isArray(entries)) {
    let invalidFix = false
    let invalidType = false
    let invalidClass = false
    let invalidRange = false
    let invalidTrace = false
    let invalidContent = false
    let invalidFilePath = false
    let invalidSeverity = false

    for (let i = 0, length = entries.length; i < length; ++i) {
      const message = entries[i]
      if (!invalidType && typeof message.type !== 'string') {
        invalidType = true
        messages.push('Message.type must be a string')
      }
      if (!invalidContent && ((typeof message.text !== 'string' && (typeof message.html !== 'string' && !(message.html instanceof HTMLElement))) || (!message.text && !message.html))) {
        invalidContent = true
        messages.push('Message.text or Message.html must have a valid value')
      }
      if (!invalidFilePath && message.filePath && typeof message.filePath !== 'string') {
        invalidFilePath = true
        messages.push('Message.filePath must be a string')
      }
      if (!invalidRange && message.range && typeof message.range !== 'object') {
        invalidRange = true
        messages.push('Message.range must be an object')
      } else if (!invalidRange && message.range) {
        const range = Range.fromObject(message.range)
        if (Number.isNaN(range.start.row) || Number.isNaN(range.start.column) || Number.isNaN(range.end.row) || Number.isNaN(range.end.column)) {
          invalidRange = true
          messages.push('Message.range should not contain NaN coordinates')
        }
      }
      if (!invalidClass && message.class && typeof message.class !== 'string') {
        invalidClass = true
        messages.push('Message.class must be a string')
      }
      if (!invalidSeverity && message.severity && !VALID_SEVERITY.has(message.severity)) {
        invalidSeverity = true
        messages.push("Message.severity must be 'error', 'warning' or 'info'")
      }
      if (!invalidTrace && message.trace && !Array.isArray(message.trace)) {
        invalidTrace = true
        messages.push('Message.trace must be an Array')
      }
      if (!invalidFix && message.fix && (typeof message.fix.range !== 'object' || typeof message.fix.newText !== 'string' || (message.fix.oldText && typeof message.fix.oldText !== 'string'))) {
        invalidFix = true
        messages.push('Message.fix must be valid')
      }
    }
  } else {
    messages.push('Linter Result must be an Array')
  }

  if (messages.length) {
    showError('Invalid Linter Result received', `These issues were encountered while processing messages from a linter named '${linterName}'`, messages)
    return false
  }

  return true
}

export {
  validateUI as ui,
  validateLinter as linter,
  validateIndie as indie,
  validateMessages as messages,
  validateMessagesLegacy as messagesLegacy,
}
