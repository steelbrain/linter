'use babel'

import {TextEditor, Emitter, CompositeDisposable} from 'atom'
export default class EditorLinter {
  constructor(editor) {
    if (!(editor instanceof TextEditor)) {
      throw new Error('Given editor is not really an editor')
    }

    this.editor = editor
    this.emitter = new Emitter()
    this.messages = new Set()
    this.markers = new WeakMap()
    this.gutter = null
    this.subscriptions = new CompositeDisposable

    this.subscriptions.add(atom.config.observe('linter.underlineIssues', underlineIssues =>
      this.underlineIssues = underlineIssues
    ))
    this.subscriptions.add(this.editor.onDidDestroy(() =>
      this.dispose()
    ))
    this.subscriptions.add(this.editor.onDidSave(() =>
      this.emitter.emit('should-lint', false)
    ))
    this.subscriptions.add(this.editor.onDidChangeCursorPosition(({oldBufferPosition, newBufferPosition}) => {
      if (newBufferPosition.row !== oldBufferPosition.row) {
        this.emitter.emit('should-update-line-messages')
      }
      this.emitter.emit('should-update-bubble')
    }))
    this.subscriptions.add(atom.config.observe('linter.gutterEnabled', gutterEnabled => {
      this.gutterEnabled = gutterEnabled
      this.handleGutter()
    }))
    // Using onDidChange instead of observe here 'cause the same function is invoked above
    this.subscriptions.add(atom.config.onDidChange('linter.gutterPosition', () =>
      this.handleGutter()
    ))
    this.subscriptions.add(this.onDidMessageAdd(message => {
      if (!this.underlineIssues && !this.gutterEnabled) {
        return // No-Op
      }
      const marker = this.editor.markBufferRange(message.range, {invalidate: 'inside'})
      this.markers.set(message, marker)
      if (this.underlineIssues) {
        this.editor.decorateMarker(marker, {
          type: 'highlight',
          class: `linter-highlight ${message.class}`
        })
      }
      if (this.gutterEnabled) {
        const item = document.createElement('span')
        item.className = `linter-gutter linter-highlight ${message.class}`
        this.gutter.decorateMarker(marker, {
          class: 'linter-row',
          item
        })
      }
    }))
    this.subscriptions.add(this.onDidMessageDelete(message => {
      if (this.markers.has(message)) {
        this.markers.get(message).destroy()
        this.markers.delete(message)
      }
    }))

    // Atom invokes the onDidStopChanging callback immediately on Editor creation. So we wait a moment
    setImmediate(() => {
      this.subscriptions.add(this.editor.onDidStopChanging(() =>
        this.emitter.emit('should-lint', true)
      ))
    })
  }

  handleGutter() {
    if (this.gutter !== null) {
      this.removeGutter()
    }
    if (this.gutterEnabled) {
      this.addGutter()
    }
  }

  addGutter() {
    const position = atom.config.get('linter.gutterPosition')
    this.gutter = this.editor.addGutter({
      name: 'linter',
      priority: position === 'Left' ? -100 : 100
    })
  }

  removeGutter() {
    if (this.gutter !== null) {
      try {
        this.gutter.destroy()
        // Atom throws when we try to remove a gutter container from a closed text editor
      } catch (err) {}
      this.gutter = null
    }
  }

  getMessages() {
    return this.messages
  }

  addMessage(message) {
    if (!this.messages.has(message)) {
      this.messages.add(message)
      this.emitter.emit('did-message-add', message)
      this.emitter.emit('did-message-change', {message, type: 'add'})
    }
  }

  deleteMessage(message) {
    if (this.messages.has(message)) {
      this.messages.delete(message)
      this.emitter.emit('did-message-delete', message)
      this.emitter.emit('did-message-change', {message, type: 'delete'})
    }
  }

  lint(onChange = false) {
    this.emitter.emit('should-lint', onChange)
  }

  onDidMessageAdd(callback) {
    return this.emitter.on('did-message-add', callback)
  }

  onDidMessageDelete(callback) {
    return this.emitter.on('did-message-delete', callback)
  }

  onDidMessageChange(callback) {
    return this.emitter.on('did-message-change', callback)
  }

  onShouldUpdateBubble(callback) {
    return this.emitter.on('should-update-bubble', callback)
  }

  onShouldUpdateLineMessages(callback) {
    return this.emitter.on('should-update-line-messages', callback)
  }

  onShouldLint(callback) {
    return this.emitter.on('should-lint', callback)
  }

  onDidDestroy(callback) {
    return this.emitter.on('did-destroy', callback)
  }

  dispose() {
    this.emitter.emit('did-destroy')
    if (this.markers.size) {
      this.markers.forEach(marker => marker.destroy())
      this.markers.clear()
    }
    this.removeGutter()
    this.subscriptions.dispose()
    this.messages.clear()
    this.emitter.dispose()
  }
}
