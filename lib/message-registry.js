/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import debounce from 'sb-debounce'
import type { Disposable, TextBuffer } from 'atom'
import { messageKey, messageKeyLegacy } from './helpers'
import type { MessagesPatch, Message, MessageLegacy, Linter } from './types'

type Linter$Message$Map = {
  buffer: ?TextBuffer,
  linter: Linter,
  changed: boolean,
  deleted: boolean,
  messages: Array<Message | MessageLegacy>,
  oldMessages: Array<Message | MessageLegacy>
}

class MessageRegistry {
  emitter: Emitter;
  messages: Array<Message | MessageLegacy>;
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
  set({ messages, linter, buffer }: { messages: Array<Message | MessageLegacy>, linter: Linter, buffer: TextBuffer }) {
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
        result.removed = result.removed.concat(entry.oldMessages)
        this.messagesMap.delete(entry)
        continue
      }
      if (!entry.changed) {
        result.messages = result.messages.concat(entry.oldMessages)
        continue
      }
      entry.changed = false
      if (!entry.oldMessages.length) {
        // All messages are new, no need to diff
        // NOTE: No need to add .key here because normalizeMessages already does that
        result.added = result.added.concat(entry.messages)
        result.messages = result.messages.concat(entry.messages)
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

      for (let i = 0, length = oldMessages.length; i < length; ++i) {
        const message = oldMessages[i]
        if (message.version === 2) {
          message.key = messageKey(message)
        } else {
          message.key = messageKeyLegacy(message)
        }
        oldKeys.add(message.key)
      }

      for (let i = 0, length = entry.messages.length; i < length; ++i) {
        const message = entry.messages[i]
        if (newKeys.has(message.key)) {
          continue
        }
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

      for (let i = 0, length = oldMessages.length; i < length; ++i) {
        const message = oldMessages[i]
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
  onDidUpdateMessages(callback: ((difference: MessagesPatch) => void)): Disposable {
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
  deleteByLinter(linter: Linter) {
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

module.exports = MessageRegistry
