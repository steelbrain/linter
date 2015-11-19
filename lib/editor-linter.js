'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import Helpers from './helpers'

export default class EditorLinter {
  constructor(editor) {
    if (typeof editor !== 'object' || typeof editor.getText !== 'function') {
      throw new Error('Given editor is not really an editor')
    }

    this.editor = editor
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable
    this.gutter = null

    this.subscriptions.add(this.editor.onDidDestroy(() =>
      this.dispose()
    ))
    this.subscriptions.add(this.editor.onDidSave(() =>
      this.emitter.emit('should-lint', false)
    ))
    this.subscriptions.add(atom.config.observe('linter.gutterEnabled', gutterEnabled => {
      this.gutterEnabled = gutterEnabled
      this.handleGutter()
    }))
    // Using onDidChange instead of observe here 'cause the same function is invoked above
    this.subscriptions.add(atom.config.onDidChange('linter.gutterPosition', () =>
      this.handleGutter()
    ))

    // TODO: Atom invokes onDid{Change, StopChanging} callbacks immediately. Workaround it
    atom.config.observe('linter.lintOnFlyInterval', (interval) => {
      if (this.changeSubscription) {
        this.changeSubscription.dispose()
      }
      this.changeSubscription = this.editor.onDidChange(Helpers.debounce(() => {
        this.emitter.emit('should-lint', true)
      }, interval))
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
        // Atom throws when we try to remove a gutter container from a closed text editor
        this.gutter.destroy()
      } catch (err) {}
      this.gutter = null
    }
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
    this.removeGutter()
    this.subscriptions.dispose()
    if (this.changeSubscription) {
      this.changeSubscription.dispose()
    }
    this.emitter.dispose()
  }
}
