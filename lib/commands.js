'use babel'

import { CompositeDisposable, Emitter } from 'atom'

export default class Commands {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.commands.add('atom-text-editor:not([mini])', {
      'linter:lint': () => this.lint(),
      'linter:toggle-active-editor': () => this.toggleActiveEditor()
    }))
  }
  toggleActiveEditor() {
    this.emitter.emit('should-toggle-active-editor')
  }
  lint() {
    this.emitter.emit('should-lint')
  }
  onShouldToggleActiveEditor(callback) {
    return this.emitter.on('should-toggle-active-editor', callback)
  }
  onShouldLint(callback) {
    return this.emitter.on('should-lint', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
