/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable, TextEditor } from 'atom'
import EditorLinter from './editor-linter'

class EditorRegistry {
  emitter: Emitter;
  lintOnOpen: boolean;
  subscriptions: CompositeDisposable;
  editorLinters: Map<TextEditor, EditorLinter>;

  constructor() {
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()
    this.editorLinters = new Map()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.config.observe('linter.lintOnOpen', (lintOnOpen) => {
      this.lintOnOpen = lintOnOpen
    }))
  }
  activate() {
    this.subscriptions.add(atom.workspace.observeTextEditors((textEditor) => {
      this.createFromTextEditor(textEditor)
    }))
  }
  get(textEditor: TextEditor): ?EditorLinter {
    return this.editorLinters.get(textEditor)
  }
  createFromTextEditor(textEditor: TextEditor): EditorLinter {
    let editorLinter = this.editorLinters.get(textEditor)
    if (editorLinter) {
      return editorLinter
    }
    editorLinter = new EditorLinter(textEditor)
    editorLinter.onDidDestroy(() => {
      this.editorLinters.delete(textEditor)
    })
    this.editorLinters.set(textEditor, editorLinter)
    this.emitter.emit('observe', editorLinter)
    if (this.lintOnOpen) {
      editorLinter.lint()
    }
    return editorLinter
  }
  observe(callback: ((editorLinter: EditorLinter) => void)): Disposable {
    this.editorLinters.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  dispose() {
    for (const entry of this.editorLinters.values()) {
      entry.dispose()
    }
    this.subscriptions.dispose()
  }
}

module.exports = EditorRegistry
