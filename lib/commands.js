/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import type { Disposable } from 'atom'
import type { State } from './types'

export default class Commands {
  state: State;
  emitter: Emitter;
  subscriptions: CompositeDisposable;

  constructor(state: State) {
    this.state = state
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.commands.add('atom-text-editor:not([mini])', {
      'linter:lint': () => this.lint(),
      'linter:toggle-active-editor': () => this.toggleActiveEditor(),
      'linter:show-linter-providers': () => this.showLinterProviders(),
    }))
  }
  lint() {
    this.emitter.emit('should-lint')
  }
  toggleActiveEditor() {
    this.emitter.emit('should-toggle-active-editor')
  }
  showLinterProviders() {
    this.emitter.emit('should-show-linter-providers')
  }
  onShouldLint(callback: Function): Disposable {
    return this.emitter.on('should-lint', callback)
  }
  onShouldToggleActiveEditor(callback: Function): Disposable {
    return this.emitter.on('should-toggle-active-editor', callback)
  }
  onShouldShowLinterProviders(callback: Function): Disposable {
    return this.emitter.on('should-show-linter-providers', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
