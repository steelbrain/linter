'use babel'

/* @flow */

import {CompositeDisposable, Emitter, Range} from 'atom'
import debounce from 'sb-debounce'
import {messageKey} from './helpers'
import type {Disposable, TextBuffer} from 'atom'

type Linter$Message = Object
type Linter$Linter = Object
type Linter$Message$Map = {
  messages: Array<Linter$Message>,
  buffer: ?TextBuffer,
  linter: Linter$Linter;
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
      found.messages = messages
    } else {
      this.messagesMap.add({messages, linter, buffer})
    }
    this.debouncedUpdate()
  }
  update() {
    const result = {added: [], removed: [], messages: []}
    const oldMessages = this.messages
    const oldKeys = new Set()
    const newKeys = new Set()

    for (const message of oldMessages) {
      message.key = messageKey(message)
      oldKeys.add(message.key)
    }
    for (const entry of this.messagesMap) {
      for (const message of entry.messages) {
        message.name = message.name || entry.linter.name || null
        message.class = (message.class || '') + ' ' + message.type.toLowerCase()
        message.key = messageKey(message)
        newKeys.add(message.key)
        if (!oldKeys.has(message.key)) {
          if (message.range && message.range.constructor.name === 'Array') {
            message.range = Range.fromObject(message.range)
          }
          result.added.push(message)
          result.messages.push(message)
        }
      }
    }

    for (const message of oldMessages) {
      if (!newKeys.has(message.key)) {
        result.removed.push(message)
      } else {
        result.messages.push(message)
      }
    }

    this.messages = result.messages
    if (result.added.length || result.removed.length) {
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
