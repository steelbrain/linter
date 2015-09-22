'use babel'

import {TextEditor, Emitter, CompositeDisposable} from 'atom'

export default class EditorLinter {
  constructor(editor) {
    if (!(editor instanceof TextEditor)) {
      throw new Error('Given editor is not really an editor')
    }

    this.editor = editor
    this.emitter = new Emitter()
    this.markers = new WeakMap()
    this.subscriptions = new CompositeDisposable

    this.subscriptions.add(this.editor.onDidDestroy(() =>
      this.emitter.emit('did-destroy')
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

    // Atom invokes the onDidStopChanging callback immediately on creation. So we wait a moment
    setImmediate(() => {
      this.subscriptions.add(this.editor.onDidStopChanging(() =>
        this.emitter.emit('should-lint', true)
      ))
    })
  }

  updateMarkers({added, removed}) {
    // TODO: Handle the path validation in notifier
    const editorPath = this.editor.getPath()

    removed.forEach(message => {
      if (!this.markers.has(message)) return

      const marker = this.markers.get(message)
      marker.destroy()
      this.markers.delete(marker)
    })

    added.forEach(message => {
      if (!message.range || !message.filePath || message.filePath !== editorPath) return

      const marker = this.editor.markBufferRange(message.range, {invalidate: 'inside'})
      this.markers.set(message, marker)
      this.editor.decorateMarker(marker, {
        type: 'line-number',
        class: `linter-highlight ${message.class}`
      })
      // TODO: `highlight` marker
    })
  }

  lint(onChange = false) {
    this.emitter.emit('should-lint', onChange)
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

  destroy() {
    this.emitter.emit('did-destroy')
    this.dispose()
  }

  dispose() {
    this.subscriptions.dispose()
  }
}
