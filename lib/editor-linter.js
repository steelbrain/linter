/* @flow */

import { Emitter, CompositeDisposable, Disposable } from 'atom'
import debounce from 'sb-debounce'
import type { TextEditor } from 'atom'
import { subscriptiveObserve } from './helpers'

export default class EditorLinter {
  editor: TextEditor;
  emitter: Emitter;
  subscriptions: CompositeDisposable;

  constructor(editor: TextEditor) {
    if (!atom.workspace.isTextEditor(editor)) {
      throw new Error('EditorLinter expects a valid TextEditor')
    }

    this.editor = editor
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.editor.onDidDestroy(() =>
      this.dispose()
    ))
    this.subscriptions.add(this.editor.onDidSave(debounce(() =>
      this.emitter.emit('should-lint', false)
    ), 16, true))
    // NOTE: TextEditor::onDidChange immediately invokes the callback if the text editor was *just* created
    // Using TextBuffer::onDidChange doesn't have the same behavior so using it instead.
    this.subscriptions.add(subscriptiveObserve(atom.config, 'linter.lintOnChangeInterval', interval =>
      this.editor.getBuffer().onDidChange(debounce(() => {
        this.emitter.emit('should-lint', true)
      }, interval))
    ))
  }
  getEditor(): TextEditor {
    return this.editor
  }
  lint(onChange: boolean = false) {
    this.emitter.emit('should-lint', onChange)
  }
  onShouldLint(callback: Function): Disposable {
    return this.emitter.on('should-lint', callback)
  }
  onDidDestroy(callback: Function): Disposable {
    return this.emitter.on('did-destroy', callback)
  }
  dispose() {
    this.emitter.emit('did-destroy')
    this.subscriptions.dispose()
    this.emitter.dispose()
  }
}
