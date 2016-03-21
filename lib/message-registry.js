'use babel'

/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import debounce from 'sb-debounce'
import { fillMessage } from './helpers'
import type { Disposable, TextBuffer } from 'atom'
import type { Linter$Difference, Linter$Linter, Linter$Message } from './types'

type Linter$Message$Map = {
  buffer: ?TextBuffer,
  linter: Linter$Linter,
  changed: boolean,
  deleted: boolean,
  messages: Array<Linter$Message>,
  oldMessages: Array<Linter$Message>
}

export default class MessageRegistry {
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
  set({ messages, linter, buffer }: { messages: Array<Linter$Message>, linter: Linter$Linter, buffer: TextBuffer }) {
    let found = null
    for (const entry of this.messagesMap) {
      if (entry.buffer === buffer && entry.linter === linter) {
        found = entry
        break
      }
    }

    if (found) {
      found.messages = messages
      found.changed = true
    } else {
      this.messagesMap.add({ messages, linter, buffer, oldMessages: [], changed: true, deleted: false })
    }
    this.debouncedUpdate()
  }
  update() {
    const result = { added: [], removed: [], messages: [] }

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
          fillMessage(message, entry.linter.name)
        }
        entry.oldMessages = entry.messages
        continue
      }
      if (!entry.messages.length) {
        // All messages are old, no need to diff
        result.removed = result.removed.concat(entry.oldMessages)
        entry.oldMessages = []
        continue
      }

      const newKeys = new Set()
      const oldKeys = new Set()
      const oldMessages = entry.oldMessages
      let foundNew = false
      entry.oldMessages = []

      for (const message of oldMessages) {
        oldKeys.add(message.key)
      }

      for (const message of entry.messages) {
        fillMessage(message, entry.linter.name)
        newKeys.add(message.key)
        if (!oldKeys.has(message.key)) {
          foundNew = true
          result.added.push(message)
          result.messages.push(message)
          entry.oldMessages.push(message)
        }
      }

      if (!foundNew && entry.messages.length === oldMessages.length) {
        // Messages are unchanged
        result.messages = result.messages.concat(oldMessages)
        entry.oldMessages = oldMessages
        continue
      }

      for (const message of oldMessages) {
        if (newKeys.has(message.key)) {
          entry.oldMessages.push(message)
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
  onDidUpdateMessages(callback: ((difference: Linter$Difference) => void)): Disposable {
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
