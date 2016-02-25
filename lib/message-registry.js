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
  deleted: boolean,
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
      this.messagesMap.add({messages, linter, buffer, oldMessages: [], changed: true, deleted: false})
    }
    this.debouncedUpdate()
  }
  update() {
    const result = {added: [], removed: [], messages: []}

    for (const entry of this.messagesMap) {
      if (entry.deleted) {
        result.removed = result.removed.concat(entry.messages)
        this.messagesMap.delete(entry)
        continue
      }
      if (!entry.changed) {
        result.messages = result.messages.concat(entry.messages)
        continue
      }
      entry.changed = false
      if (!entry.oldMessages.length) {
        // All messages are new, no need to diff
        result.added = result.added.concat(entry.messages)
        result.messages = result.messages.concat(entry.messages)
        for (const message of entry.messages) {
          message.name = message.name || entry.linter.name || null
        }
        continue
      }
      if (!entry.messages.length) {
        // All messages are old, no need to diff
        result.removed = result.removed.concat(entry.oldMessages)
        continue
      }

      const newKeys = new Set()
      const oldKeys = new Set()
      let foundNew = false

      for (const message of entry.oldMessages) {
        message.key = messageKey(message)
        oldKeys.add(message.key)
      }

      for (const message of entry.messages) {
        message.name = message.name || entry.linter.name || null
        message.key = messageKey(message)
        newKeys.add(message.key)
        if (!oldKeys.has(message.key)) {
          foundNew = true
          result.added.push(message)
          result.messages.push(message)
        }
      }

      if (!foundNew && entry.messages.length === entry.oldMessages.length) {
        // Messages are unchanged
        result.messages = result.messages.concat(entry.oldMessages)
        continue
      }

      for (const message of entry.oldMessages) {
        if (newKeys.has(message.key)) {
          result.messages.push(message)
        } else {
          result.removed.push(message)
        }
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
        entry.deleted = true
      }
    }
    this.debouncedUpdate()
  }
  deleteByLinter(linter: Linter$Linter) {
    for (const entry of this.messagesMap) {
      if (entry.linter === linter) {
        entry.deleted = true
      }
    }
    this.debouncedUpdate()
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
