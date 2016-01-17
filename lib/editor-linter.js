'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import {debounce} from './helpers'

export default class EditorLinter {
  constructor(editor) {
    if (typeof editor !== 'object' || typeof editor.getText !== 'function') {
      throw new Error('Given editor is not really an editor')
    }

    this.editor = editor
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable

    this.subscriptions.add(this.editor.onDidDestroy(() =>
      this.dispose()
    ))
    this.subscriptions.add(this.editor.onDidSave(() =>
      this.emitter.emit('should-lint', false)
    ))

    // TODO: Atom invokes onDid{Change, StopChanging} callbacks immediately. Workaround it
    atom.config.observe('linter.lintOnFlyInterval', (interval) => {
      if (this.changeSubscription) {
        this.changeSubscription.dispose()
      }
      this.changeSubscription = this.editor.onDidChange(debounce(() => {
        this.emitter.emit('should-lint', true)
      }, interval))
    })

  }

  lint(onChange = false) {
    this.emitter.emit('should-lint', onChange)
  }

  onShouldLint(callback) {
    return this.emitter.on('should-lint', callback)
  }

  onDidDestroy(callback) {
    return this.emitter.on('did-destroy', callback)
  }

  dispose() {
    this.emitter.emit('did-destroy')
    this.subscriptions.dispose()
    if (this.changeSubscription) {
      this.changeSubscription.dispose()
    }
    this.emitter.dispose()
  }
}
