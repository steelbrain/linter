'use babel'

import {Emitter, CompositeDisposable} from 'atom'
const EditorLinter = require('./editor-linter')

export default class EditorRegistry {
  constructor() {
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()
    this.editorLinters = new Map()

    this.subscriptions.add(this.emitter)
  }

  create(textEditor) {
    const editorLinter = new EditorLinter(textEditor)
    this.editorLinters.set(textEditor, editorLinter)
    this.emitter.emit('observe', editorLinter)
    editorLinter.onDidDestroy(() =>
      this.editorLinters.delete(textEditor)
    )
    return editorLinter
  }

  has(textEditor) {
    return this.editorLinters.has(textEditor)
  }

  forEach(textEditor) {
    this.editorLinters.forEach(textEditor)
  }

  ofPath(path) {
    for (let editorLinter of this.editorLinters) {
      if (editorLinter[0].getPath() === path) {
        return editorLinter[1]
      }
    }
  }

  ofTextEditor(textEditor) {
    return this.editorLinters.get(textEditor)
  }

  ofActiveTextEditor() {
    return this.ofTextEditor(atom.workspace.getActiveTextEditor())
  }

  observe(callback) {
    this.forEach(callback)
    return this.emitter.on('observe', callback)
  }

  dispose() {
    this.subscriptions.dispose()
    this.editorLinters.forEach(function(editorLinter) {
      editorLinter.dispose()
    })
    this.editorLinters.clear()
  }
}
