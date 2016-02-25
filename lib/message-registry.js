'use babel'

/* @flow */

import {CompositeDisposable, Emitter, Range} from 'atom'
import debounce from 'sb-debounce'
import {messageKey} from './helpers'
import type {Disposable, TextBuffer} from 'atom'

type Linter$Message = Object
type Linter$Linter = Object
type Linter$Message$Map = {
  buffer: ?TextBuffer,
  linter: Linter$Linter,
  changed: boolean,
  messages: Array<Linter$Message>,
  oldMessages: Array<Linter$Message>
}
type Linter$MessageRegistry$Result = {
  added: Array<Linter$Message>,
  removed: Array<Linter$Message>,
  messages: Array<Linter$Message>
}

export class MessageRegistry {
  emitter: Emitter;
  messages: Array<Linter$Message>;
  messagesMap: Set<Linter$Message$Map>;
  subscriptions: CompositeDisposable;
  debouncedUpdate: (() => void);

  constructor() {
    this.emitter = new Emitter()
    this.messages = []
    this.messagesMap = new Set()
    this.subscriptions = new CompositeDisposable()
    this.debouncedUpdate = debounce(this.update, 100, true)

    this.subscriptions.add(this.emitter)
  }
  set({messages, linter, buffer}: Linter$Message$Map) {
    let found = null
    for (const entry of this.messagesMap) {
      if (entry.buffer === buffer && entry.linter === linter) {
        found = entry
        break
      }
    }

    if (found) {
      found.oldMessages = found.messages
      found.messages = messages
      found.changed = true
    } else {
      this.messagesMap.add({messages, linter, buffer, oldMessages: [], changed: true})
    }
    this.debouncedUpdate()
  }
  update() {
    const result = {added: [], removed: [], messages: []}

    for (const entry of this.messagesMap) {
      if (entry.changed) {
        if (entry.oldMessages.length) {
          const oldKeys = new Set()
          const newKeys = new Set()
          const oldLength = entry.oldMessages.length
          const newLength = entry.messages.length
          let i
          let foundNew = false
          for (i = 0; i < oldLength; ++i) {
            const message = entry.oldMessages[i]
            message.key = messageKey(message)
            oldKeys.add(message.key)
          }
          for (i = 0; i < newLength; ++i) {
            const message = entry.messages[i]
            message.name = message.name || entry.linter.name || null
            message.key = messageKey(message)
            newKeys.add(message.key)
            if (!oldKeys.has(message.key)) {
              foundNew = true
              result.added.push(message)
              result.messages.push(message)
            }
          }
          if (oldLength !== newLength || foundNew) {
            for (i = 0; i < oldLength; ++i) {
              const message = entry.oldMessages[i]
              if (newKeys.has(message.key)) {
                result.messages.push(message)
              } else {
                result.removed.push(message)
              }
            }
          } else {
            result.messages = result.messages.concat(entry.oldMessages)
          }
        } else {
          result.added = result.added.concat(entry.messages)
          result.messages = result.messages.concat(entry.messages)
          const length = entry.messages.length
          for (let i = 0; i < length; ++i) {
            const message = entry.messages[i]
            message.name = message.name || entry.linter.name || null
          }
        }
      } else {
        result.messages = result.messages.concat(entry.oldMessages)
      }
    }

    if (result.added.length || result.removed.length) {
      this.messages = result.messages
      this.emitter.emit('did-update-messages', result)
    }
  }
  onDidUpdateMessages(callback: Linter$MessageRegistry$Result): Disposable {
    return this.emitter.on('did-update-messages', callback)
  }
  deleteByBuffer(buffer: TextBuffer) {
    for (const entry of this.messagesMap) {
      if (entry.buffer === buffer) {
        this.messagesMap.delete(entry)
      }
    }
    this.debouncedUpdate()
  }
  deleteByLinter(linter: Linter$Linter) {
    for (const entry of this.messagesMap) {
      if (entry.linter === linter) {
        this.messagesMap.delete(entry)
      }
    }
    this.debouncedUpdate()
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
