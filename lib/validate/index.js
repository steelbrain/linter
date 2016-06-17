'use babel'

/* @flow */

import { showError } from './helpers'
import type { UI, Linter, Message, IndieConfig } from '../types'

const VALID_SEVERITY = new Set(['error', 'warning', 'info'])

export function ui(ui: UI): boolean {
  const messages = []

  if (ui && typeof ui === 'object') {
    if (typeof ui.name !== 'string') {
      messages.push('UI.name must be a string')
    }
    if (typeof ui.activate !== 'function') {
      messages.push('UI.activate must be a function')
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
    showError('Invalid UI received', `These issues were encountered while registering the UI named '${ui && ui.name || 'Unknown'}'`, messages)
    return false
  }

  return true
}

export function linter(linter: Linter): boolean {
  const messages = []

  if (linter && typeof linter === 'object') {
    if (typeof linter.name !== 'string') {
      messages.push('Linter.name must be a string')
    }
    if (typeof linter.scope !== 'string' || (linter.scope !== 'file' && linter.scope !== 'project')) {
      messages.push("Linter.scope must be either 'file' or 'project'")
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
    showError('Invalid Linter received', `These issues were encountered while registering a Linter named '${linter && linter.name || 'Unknown'}'`, messages)
    return false
  }

  return true
}

export function indie(indie: IndieConfig): boolean {
  const messages = []

  if (indie && typeof indie === 'object') {
    if (typeof indie.name !== 'string') {
      messages.push('Indie.name must be a string')
    }
  } else {
    messages.push('Indie must be an object')
  }

  if (messages.length) {
    showError('Invalid Indie received', `These issues were encountered while registering an Indie Linter named '${indie && indie.name || 'Unknown'}'`, messages)
    return false
  }

  return true
}

export function messages(linterName: string, entries: Array<Message>): boolean {
  const messages = []

  if (Array.isArray(entries)) {
    let invalidSource = false
    let invalidExcerpt = false
    let invalidLocation = false
    let invalidSeverity = false
    let invalidSolution = false
    let invalidReference = false
    let invalidDescription = false

    for (let i = 0, length = entries.length; i < length; ++i) {
      const message = entries[i]
      if (!invalidLocation && (!message.location || typeof message.location !== 'object' || typeof message.location.file !== 'string' || typeof message.location.position !== 'object' || !message.location.position)) {
        invalidLocation = true
        messages.push('Message.position must be valid')
      }
      if (!invalidSolution && message.solutions && !Array.isArray(message.solutions)) {
        invalidSolution = true
        messages.push('Message.solution must be valid')
      }
      if (!invalidSource && message.source && (typeof message.source !== 'object' || typeof message.source.file !== 'string' || typeof message.source.position !== 'object' || !message.source.position)) {
        invalidSource = true
        messages.push('Message.source must be valid')
      }
      if (!invalidExcerpt && typeof message.excerpt !== 'string') {
        invalidExcerpt = true
        messages.push('Message.excerpt must be a string')
      }
      if (!invalidSeverity && !VALID_SEVERITY.has(message.severity)) {
        invalidSeverity = true
        messages.push("Message.severity must be 'error', 'warning' or 'info'")
      }
      if (!invalidReference && message.reference && typeof message.reference !== 'string') {
        invalidReference = true
        messages.push('Message.reference must be null or a string')
      }
      if (!invalidDescription && typeof message.description !== 'undefined' && !Array.isArray(message.description)) {
        invalidDescription = true
        messages.push('Message.description must be a Stringish Array')
      }
    }
  } else {
    messages.push('Linter Result must be an Array')
  }

  if (messages.length) {
    showError('Invalid Linter Result received', `These issues were encountered while processing messages from a linter named '${linterName}`, messages)
    return false
  }

  return true
}
