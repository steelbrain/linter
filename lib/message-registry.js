/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import debounce from 'lodash/debounce'
import type { Disposable, TextBuffer } from 'atom'
import { messageKey, updateKeys, createKeyMessageMap, flagMessages, mergeArray } from './helpers'
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

    // check if the linter has been already set
    let found = null
    for (const entry of this.messagesMap) {
      if (entry.buffer === buffer && entry.linter === linter) {
        found = entry
        break
      }
    }

    if (found) {
      // found linter
      found.messages = messages
      found.changed = true
    } else {
      // new linter
      this.messagesMap.add({ messages, linter, buffer, oldMessages: [], changed: true, deleted: false })
    }
    this.debouncedUpdate()
  }
  update() {

    // the final object sent to UI that contains the messages tagged for adding/removeal. messages is all the kept + added messages
    const result = { added: [], removed: [], messages: [] }

    // looping over each linter
    for (const entry of this.messagesMap) {

      // if linter is deleted
      // tag the linter's cache for removal and delete it from the map
      if (entry.deleted) {
        mergeArray(result.removed, entry.oldMessages)
        this.messagesMap.delete(entry)
        continue
      }

      // if the linter is not changed
      // just use its cache (no added/removed and everything is kept) and skip the rest
      if (!entry.changed) {
        // TODO When this code acutally runs?!
        mergeArray(result.messages, entry.oldMessages)
        continue
      }

      // All the messages of the linter are new, no need to diff
      // tag the messages for adding and save them to linter's cache
      if (!entry.oldMessages.length) {
        // NOTE: No need to add .key here because normalizeMessages already does that
        mergeArray(result.added, entry.messages)
        mergeArray(result.messages, entry.messages)
        entry.oldMessages = entry.messages
        continue
      }

      // The linter has no messages anymore
      // tag all of its messages from cache for removal and empty the cache
      if (!entry.messages.length) {
        mergeArray(result.removed, entry.oldMessages)
        entry.oldMessages = []
        continue
      }

      // In all the other situations:
      // perform diff checking between the linter's new messages and its cache

      const { oldMessages } = entry

      // create a map from keys to oldMessages
      const keyMessageMap = createKeyMessageMap(oldMessages)

      // flag messages as oldKept, oldRemoved, newAdded
      const flaggedMessages = flagMessages(entry.messages, keyMessageMap)

      // update the result and cache
      if (flaggedMessages !== null) {
        const { oldKept, oldRemoved, newAdded } = flaggedMessages
        mergeArray(result.added, newAdded)
        mergeArray(result.removed, oldRemoved)
        const allThisEntry = newAdded.concat(oldKept)
        mergeArray(result.messages, allThisEntry)
        entry.oldMessages = allThisEntry // update chache
      }
    }

    // if any messages is removed or added, then update the UI
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
