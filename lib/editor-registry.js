'use babel'

/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import EditorLinter from './editor-linter'
import type { Disposable, TextEditor } from 'atom'

export default class EditorRegistry {
  emitter: Emitter;
  subscriptions: CompositeDisposable;
  editorLinters: Map<TextEditor, EditorLinter>;

  constructor() {
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()
    this.editorLinters = new Map()

    this.subscriptions.add(this.emitter)
  }
  create(textEditor: TextEditor): EditorLinter {
    const editorLinter = new EditorLinter(textEditor)
    this.editorLinters.set(textEditor, editorLinter)
    this.emitter.emit('observe', editorLinter)
    editorLinter.onDidDestroy(() =>
      this.editorLinters.delete(textEditor)
    )
    this.subscriptions.add(editorLinter)
    return editorLinter
  }
  has(textEditor: TextEditor): boolean {
    return this.editorLinters.has(textEditor)
  }
  forEach(callback: Function) {
    this.editorLinters.forEach(callback)
  }
  ofTextEditor(textEditor: TextEditor): ?EditorLinter {
    return this.editorLinters.get(textEditor)
  }
  ofActiveTextEditor(): ?EditorLinter {
    return this.ofTextEditor(atom.workspace.getActiveTextEditor())
  }
  observe(callback: Function): Disposable {
    this.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  dispose() {
    this.subscriptions.dispose()
    this.editorLinters.clear()
  }
}
