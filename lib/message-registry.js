/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import debounce from 'lodash/debounce'
import type { Disposable, TextBuffer } from 'atom'
import { messageKey, updateKeys, createKeyMessageMap, flagMessages } from './helpers'
import type { MessagesPatch, Message, Linter } from './types'

type Linter$Message$Map = {
  buffer: ?TextBuffer,
  linter: Linter,
  changed: boolean,
  deleted: boolean,
  messages: Array<Message>,
  oldMessages: Array<Message>,
}

class MessageRegistry {
  emitter: Emitter
  messages: Array<Message>
  messagesMap: Set<Linter$Message$Map>
  subscriptions: CompositeDisposable
  debouncedUpdate: () => void

  constructor() {
    this.emitter = new Emitter()
    this.messages = []
    this.messagesMap = new Set()
    this.subscriptions = new CompositeDisposable()
    this.debouncedUpdate = debounce(this.update, 100, { leading: true })

    this.subscriptions.add(this.emitter)
  }
  set({ messages, linter, buffer }: { messages: Array<Message>, linter: Linter, buffer: TextBuffer }) {
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

      const { oldMessages } = entry

      // update the key of oldMessages
      updateKeys(oldMessages)

      // create a map from keys to oldMessages
      const keyMessageMap = createKeyMessageMap(oldMessages)

      // flag messages as oldKept, oldRemoved, newAdded
      const flaggedMessages = flagMessages(entry.messages, keyMessageMap)

      // update the result and cache
      if (flaggedMessages !== null) {
        const { oldKept, oldRemoved, newAdded } = flaggedMessages
        result.added = result.added.concat(newAdded)
        result.removed = result.removed.concat(oldRemoved)
        const allThisEntry = newAdded.concat(oldKept)
        result.messages = result.messages.concat(allThisEntry)
        entry.oldMessages = allThisEntry // update chache
      }
    }

    if (result.added.length || result.removed.length) {
      this.messages = result.messages
      this.emitter.emit('did-update-messages', result)
    }
  }
  onDidUpdateMessages(callback: (difference: MessagesPatch) => void): Disposable {
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

export default MessageRegistry
