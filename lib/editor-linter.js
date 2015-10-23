'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import Helpers from './helpers'

export default class EditorLinter {
  constructor(editor) {
    if (typeof editor !== 'object' || typeof editor.markBufferRange !== 'function') {
      throw new Error('Given editor is not really an editor')
    }

    this.editor = editor
    this.emitter = new Emitter()
    this.messages = new Set()
    this.markers = new Map()
    this.subscriptions = new CompositeDisposable
    this.gutter = null
    this.countLineMessages = 0

    this.subscriptions.add(atom.config.observe('linter.underlineIssues', underlineIssues =>
      this.underlineIssues = underlineIssues
    ))
    this.subscriptions.add(atom.config.observe('linter.showErrorInline', showBubble =>
      this.showBubble = showBubble
    ))
    this.subscriptions.add(this.editor.onDidDestroy(() =>
      this.dispose()
    ))
    this.subscriptions.add(this.editor.onDidSave(() =>
      this.emitter.emit('should-lint', false)
    ))
    this.subscriptions.add(this.editor.onDidChangeCursorPosition(({oldBufferPosition, newBufferPosition}) => {
      if (newBufferPosition.row !== oldBufferPosition.row) {
        this.calculateLineMessages(newBufferPosition.row)
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
      if (!this.underlineIssues && !this.gutterEnabled && !this.showBubble || !message.range) {
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

    // TODO: Atom invokes onDid{Change, StopChanging} callbacks immediately. Workaround it
    atom.config.observe('linter.lintOnFlyInterval', (interval) => {
      if (this.changeSubscription) {
        this.changeSubscription.dispose()
      }
      this.changeSubscription = this.editor.onDidChange(Helpers.debounce(() => {
        this.emitter.emit('should-lint', true)
      }, interval))
    })

    this.active = true
  }

  set active(value) {
    value = Boolean(value)
    if (value !== this._active) {
      this._active = value
      if (this.messages.size) {
        this.messages.forEach(message => message.currentFile = value)
      }
    }
  }
  get active() {
    return this._active
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
        // Atom throws when we try to remove a gutter container from a closed text editor
        this.gutter.destroy()
      } catch (err) {}
      this.gutter = null
    }
  }

  getMessages() {
    return this.messages
  }

  addMessage(message) {
    if (!this.messages.has(message)) {
      if (this.active) {
        message.currentFile = true
      }
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

  calculateLineMessages(row) {
    if (atom.config.get('linter.showErrorTabLine')) {
      if (row === null) {
        row = this.editor.getCursorBufferPosition().row
      }
      this.countLineMessages = 0
      this.messages.forEach(message => {
        if (message.currentLine = message.range && message.range.intersectsRow(row)) {
          this.countLineMessages++
        }
      })
    } else {
      this.countLineMessages = 0
    }
    this.emitter.emit('did-calculate-line-messages', this.countLineMessages)
    return this.countLineMessages
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

  onDidCalculateLineMessages(callback) {
    return this.emitter.on('did-calculate-line-messages', callback)
  }

  onShouldUpdateBubble(callback) {
    return this.emitter.on('should-update-bubble', callback)
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
    if (this.changeSubscription) {
      this.changeSubscription.dispose()
    }
    this.emitter.dispose()
    this.messages.clear()
  }
}
