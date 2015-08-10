'use babel'
import {Emitter, TextEditor, CompositeDisposable} from 'atom'

const Validate = require('./validate')
const Helpers = require('./helpers')

class MessageRegistry {
  constructor() {
    this.hasChanged = false
    this.shouldRefresh = true
    this.publicMessages = []
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()
    this.linterResponses = new Map()
    this.editorMessages = new Map()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.config.observe('linter.ignoredMessageTypes', value => this.ignoredMessageTypes = (value || [])))

    const UpdateMessages = () => {
      if (this.shouldRefresh) {
        if (this.hasChanged) {
          this.hasChanged = false
          this.updatePublic()
        }
        Helpers.requestUpdateFrame(UpdateMessages)
      }
    }
    Helpers.requestUpdateFrame(UpdateMessages)
  }
  set({linter, messages, editor}) {
    if (!linter.status) return
    try {
      Validate.messages(messages)
    } catch (e) { return Helpers.error(e) }
    messages = messages.filter(i => this.ignoredMessageTypes.indexOf(i.type) === -1)
    if (linter.scope === 'file') {
      if (!editor.alive) return
      if (!(editor instanceof TextEditor)) throw new Error("Given editor isn't really an editor")
      if (!this.editorMessages.has(editor))
        this.editorMessages.set(editor, new Map())
      this.editorMessages.get(editor).set(linter, messages)
    } else { // It's project
      this.linterResponses.set(linter, messages)
    }
    this.hasChanged = true
  }
  updatePublic() {
    let publicMessages = []
    let added = []
    let removed = []
    let currentKeys
    let lastKeys

    this.linterResponses.forEach(messages => publicMessages = publicMessages.concat(messages))
    this.editorMessages.forEach(editorMessages =>
      editorMessages.forEach(messages => publicMessages = publicMessages.concat(messages))
    )

    currentKeys = publicMessages.map(i => i.key)
    lastKeys = this.publicMessages.map(i => i.key)

    publicMessages.forEach(function(i) {
      if (lastKeys.indexOf(i.key) === -1)
        added.push(i)
    })
    this.publicMessages.forEach(function(i) {
      if (currentKeys.indexOf(i.key) === -1)
        removed.push(i)
    })
    this.publicMessages = publicMessages
    this.emitter.emit('did-update-messages', {added, removed, messages: publicMessages})
  }
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }
  deleteMessages(linter) {
    if (linter.scope === 'file') {
      this.editorMessages.forEach(r => r.delete(linter))
      this.hasChanged = true
    } else if(this.linterResponses.has(linter)) {
      this.linterResponses.delete(linter)
      this.hasChanged = true
    }
  }
  deleteEditorMessages(editor) {
    if (!this.editorMessages.has(editor)) return
    this.editorMessages.delete(editor)
    this.hasChanged = true
  }
  deactivate() {
    this.shouldRefresh = false
    this.subscriptions.dispose()
    this.linterResponses.clear()
    this.editorMessages.clear()
  }
}

module.exports = MessageRegistry
