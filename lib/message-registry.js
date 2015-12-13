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
    let added = []
    let removed = []

    this.queue.forEach(({messages, linter, editor}) => {
      let foundNew = false
      let foundChange = false

      const lastMessages = this.getMessages(linter, editor)
      const currentMessages = new Map()

      if (lastMessages.size === 0) {
        added = messages
        messages.forEach(function(message) {
          currentMessages.set(message.key, message)
        })
        foundNew = true
      } else {
        messages.forEach(function(message) {
          if (!lastMessages.has(message.key)) {
            foundChange = true
            added.push(message)
          }
          currentMessages.set(message.key, message)
        })

        if (!foundChange && messages.length === lastMessages.size) {
          // Nothing has changed here, no need to look for removed message
        } else {
          lastMessages.forEach(function(_, key) {
            if (!currentMessages.has(key)) {
              foundChange = true
              removed.push(lastMessages.get(key))
            }
          })
        }
      }

      if (foundChange || foundNew) {
        this.setMessages(linter, editor, currentMessages)
      }
    })

    if (added.length || removed.length) {
      const getAllMessages = () => this.getAllMessages()
      this.emitter.emit('did-update-messages', {added, removed, get messages() {
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
    const bufferMessages = this.messages.get(editor)
    return (bufferMessages ? bufferMessages.get(linter) : undefined) || new Map()
  }
  setMessages(linter, editor, messages) {
    let bufferMessages = this.messages.get(editor)

    if (!bufferMessages) {
      this.messages.set(editor, bufferMessages = new Map())
    }
    bufferMessages.set(linter, messages)
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
