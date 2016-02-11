'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import {showError, requestUpdateFrame} from './helpers'

const Validate = require('./validate')

class MessageRegistry {
  constructor() {
    this.hasChanged = false
    this.shouldRefresh = true
    this.publicMessages = []
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()
    this.linterResponses = new Map()
    this.messages = new Map()

    this.subscriptions.add(this.emitter)

    const UpdateMessages = () => {
      if (this.shouldRefresh) {
        if (this.hasChanged) {
          this.hasChanged = false
          this.updatePublic()
        }
        requestUpdateFrame(UpdateMessages)
      }
    }
    requestUpdateFrame(UpdateMessages)
  }
  set({linter, messages, editorLinter}) {
    if (linter.deactivated) {
      return
    }
    try {
      Validate.messages(messages, linter)
    } catch (e) {
      return showError(e)
    }

    if (linter.scope === 'file') {
      if (!editorLinter || !editorLinter.editor.isAlive()) {
        return
      }
      const messagesKey = editorLinter.editor.getBuffer()
      if (!this.messages.has(messagesKey)) {
        this.messages.set(messagesKey, new Map())
      }
      this.messages.get(messagesKey).set(linter, messages)
    } else { // It's project
      this.linterResponses.set(linter, messages)
    }
    this.hasChanged = true
  }
  updatePublic() {
    let latestMessages = []
    let publicMessages = []
    let added = []
    let removed = []
    let currentKeys = []
    let lastKeys = []

    this.linterResponses.forEach(messages => latestMessages = latestMessages.concat(messages))
    this.messages.forEach(bufferMessages =>
      bufferMessages.forEach(messages => latestMessages = latestMessages.concat(messages))
    )

    for (let i  of latestMessages) {
      currentKeys.push(i.key)
    }
    for (let i of this.publicMessages) {
      lastKeys.push(i.key)
    }

    for (let i of latestMessages) {
      if (lastKeys.indexOf(i.key) === -1) {
        added.push(i)
        publicMessages.push(i)
      }
    }

    for (let i of this.publicMessages)
      if (currentKeys.indexOf(i.key) === -1) {
        removed.push(i)
      } else publicMessages.push(i)

    if (added.length || removed.length) {
      this.publicMessages = publicMessages
      this.emitter.emit('did-update-messages', {added, removed, messages: publicMessages})
    }
  }
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }
  deleteMessages(linter) {
    if (linter.scope === 'file') {
      this.messages.forEach(r => r.delete(linter))
      this.hasChanged = true
    } else if(this.linterResponses.has(linter)) {
      this.linterResponses.delete(linter)
      this.hasChanged = true
    }
  }
  deleteEditorMessages(editorLinter) {
    const messagesKey = editorLinter && editorLinter.editor.getBuffer()
    if (this.messages.has(messagesKey)) {
      this.messages.delete(messagesKey)
      this.hasChanged = true
    }
  }
  dispose() {
    this.shouldRefresh = false
    this.subscriptions.dispose()
    this.linterResponses.clear()
    this.messages.clear()
  }
}

module.exports = MessageRegistry
