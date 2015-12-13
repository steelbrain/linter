'use babel'

import {Emitter, CompositeDisposable} from 'atom'

const Validate = require('./validate')
const Helpers = require('./helpers')

export default class MessageRegistry {
  constructor() {
    this.active = true
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    // Map<EditorLinter | null, Map<Linter, array<Message>>>
    this.messages = new Map()
    this.queue = []

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.config.observe('linter.ignoredMessageTypes', ignoredMessageTypes => {
      this.ignoredMessageTypes = new Set(ignoredMessageTypes)
    }))

    const UpdateMessages = () => {
      if (this.active) {
        if (this.queue.length) {
          this.processQueue()
        }
        Helpers.requestUpdateFrame(UpdateMessages)
      }
    }
    UpdateMessages()
  }
  set({linter, messages, editor = null}) {
    // Do not set messages if the linter is deactivated
    if (linter.deactivated) {
      return
    }

    // Validate messages
    try {
      Validate.messages(messages, linter)
    } catch (e) {
      return Helpers.error(e)
    }

    // Filter ignored ones
    if (this.ignoredMessageTypes.size) {
      messages = messages.filter(i => !this.ignoredMessageTypes.has(i.type))
    }

    this.queue.push({messages, linter, editor})
  }
  processQueue() {
    let allAdded = []
    let allRemoved = []

    this.queue.forEach(({messages, linter, editor}) => {
      let added = []

      const lastMessages = this.getMessages(linter, editor)
      const currentKeys = new Set()

      if (lastMessages.size === 0) {
        added = messages
      } else {
        messages.forEach(function(message) {
          if (!lastMessages.has(message.key)) {
            added.push(message)
          } else {
            currentKeys.add(message.key)
          }
        })

        if (!added.length && messages.length === lastMessages.size) {
          // Nothing has changed here, no need to look for removed message
        } else {
          lastMessages.forEach(function(_, key) {
            if (!currentKeys.has(key)) {
              allRemoved.push(lastMessages.get(key))
              lastMessages.delete(key)
            }
          })
        }
      }

      if (added.length) {
        allAdded = allAdded.concat(added)
        added.forEach(function(message) {
          lastMessages.set(message.key, message)
        })
      }
    })

    if (allAdded.length || allRemoved.length) {
      const getAllMessages = () => this.getAllMessages()
      this.emitter.emit('did-update-messages', {added: allAdded, removed: allRemoved, get messages() {
        return getAllMessages()
      }})
    }
  }
  getAllMessages() {
    let messages = []
    this.messages.forEach(function(bufferMessages) {
      bufferMessages.forEach(function(linterMessages) {
        linterMessages.forEach(function(message) {
          messages.push(message)
        })
      })
    })
    return messages
  }
  getMessages(linter, editor) {
    let bufferMessages = this.messages.get(editor)
    if (!bufferMessages) {
      this.messages.set(editor, bufferMessages = new Map())
    }
    let linterMessages = bufferMessages.get(linter)
    if (!linterMessages) {
      bufferMessages.set(linter, linterMessages = new Map())
    }
    return linterMessages
  }
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }
  deleteMessages(linter) {
    // TODO
  }
  deleteEditorMessages(editorLinter) {
    // TODO
  }
  dispose() {
    this.active = false
    this.subscriptions.dispose()
    this.messages.clear()
    this.queue = []
  }
}
