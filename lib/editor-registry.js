'use babel'

import {Emitter, CompositeDisposable} from 'atom'
const EditorLinter = require('./editor-linter')

export default class EditorRegistry {
  constructor() {
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()
    this.editorLinters = new Map()
    this.editorLintersByPath = new Map()

    this.subscriptions.add(this.emitter)
  }

  create(textEditor) {
    const editorLinter = new EditorLinter(textEditor)
    this.editorLinters.set(textEditor, editorLinter)

    let currentPath = textEditor.getPath()
    if (currentPath) {
      this.editorLintersByPath.set(currentPath, editorLinter)
    }
    editorLinter.subscriptions.add(textEditor.onDidChangePath(path => {
      this.editorLintersByPath.delete(currentPath)
      this.editorLintersByPath.set(currentPath = path, editorLinter)
    }))

    editorLinter.onDidDestroy(() =>
      this.editorLinters.delete(textEditor)
    )
    this.emitter.emit('observe', editorLinter)
    return editorLinter
  }

  has(textEditor) {
    return this.editorLinters.has(textEditor)
  }

  forEach(textEditor) {
    this.editorLinters.forEach(textEditor)
  }

  ofPath(path) {
    return this.editorLintersByPath.get(path)
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
