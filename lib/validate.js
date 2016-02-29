'use babel'

/* @flow */

import invariant from 'assert'
import type { Linter$UI, Linter$Linter, Linter$Message } from './types'

export function ui(ui: Linter$UI): boolean {
  let message

  if (!ui || typeof ui !== 'object') {
    message = 'UI Provider must be an object'
  } else if (typeof ui.name !== 'string') {
    message = 'UI.name must be a string'
  } else if (typeof ui.activate !== 'function') {
    message = 'UI.activate must be a function'
  } else if (typeof ui.didCalculateMessages !== 'function') {
    message = 'UI.didCalculateMessages must be a function'
  } else if (typeof ui.didBeginLinting !== 'function') {
    message = 'UI.didBeginLinting must be a function'
  } else if (typeof ui.didFinishLinting !== 'function') {
    message = 'UI.didFinishLinting must be a function'
  } else if (typeof ui.dispose !== 'function') {
    message = 'UI.dispose must be a function'
  }

  if (message) {
    console.error('[Linter] Invalid UI provider received', message, ui)
    throw new Error(message)
  }

  return true
}

export function linter(linter: Linter$Linter, indie: boolean = false): boolean {
  let message

  if (!linter || typeof linter !== 'object') {
    message = 'Linter Provider must be an object'
  } else if (linter.name && typeof linter.name !== 'string') {
    message = 'Linter.name must be a string'
  } else if (!indie) {
    if (!Array.isArray(linter.grammarScopes)) {
      message = 'Linter.grammarScopes must be an array'
    } else if (typeof linter.lint !== 'function') {
      message = 'Linter.lint must be a function'
    } else if (linter.scope !== 'file' && linter.scope !== 'project') {
      message = 'Linter.scope must be either file or project'
    }
  }

  if (message) {
    console.error('[Linter] Invalid Linter provider received', message, linter)
    throw new Error(message)
  }

  return true
}

export function messages(entries: Array<Linter$Message>): boolean {
  if (!Array.isArray(entries)) {
    console.error('[Linter] Invalid Linter Result received', entries)
    throw new Error('Expected linter response to be an array, check your console for more info')
  }
  let foundError = false

  for (const entry of entries) {
    let message

    if (typeof entry.type !== 'string') {
      message = 'Linter message.type must be a string'
    } else {
      if (typeof entry.html !== 'undefined') {
        if (entry.text) {
          message = 'Linter message should either have html or text and never both'
        } else if (typeof entry.html !== 'string' && !(entry.html instanceof HTMLElement)) {
          message = 'Linter message.html must be a string or HTMLElement'
        }
      } else if (typeof entry.text !== 'undefined') {
        if (typeof entry.text !== 'string') {
          message = 'Linter message.text must be a string'
        }
      } else {
        message = 'Linter message must have either text or html'
      }
    }
    if (!message) {
      if (entry.class && typeof entry.class !== 'string') {
        message = 'Linter message.class must be a string'
      } else if (typeof entry.filePath !== 'undefined' && typeof entry.filePath !== 'string') {
        message = 'Linter message.filePath must be a string'
      } else if (entry.trace) {
        messages(entry.trace)
      }
    }

    if (message) {
      foundError = true
      console.error('[Linter] Invalid message received', message, entry)
    }
  }

  if (foundError) {
    throw new Error('Invalid linter response received, check your console for more info')
  }

  return true
}
