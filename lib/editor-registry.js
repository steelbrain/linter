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
    this.subscriptions.add(editorLinter)
    return editorLinter
  }

  getMap() {
    const map = {}
    this.editors.forEach(function(editor) {
      const path = editor.getPath()
      if (typeof map[path] === 'undefined') {
        map[path] = [editor]
      } else {
        map[path].push(editor)
      }
    })
    return map
  }

  has(textEditor) {
    return this.editorLinters.has(textEditor)
  }

  forEach(textEditor) {
    this.editorLinters.forEach(textEditor)
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
    this.editorLinters.clear()
  }
}
