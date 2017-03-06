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
      'linter:debug': () => this.debug(),
      'linter:toggle-active-editor': () => this.toggleActiveEditor(),
    }))
  }
  lint() {
    this.emitter.emit('should-lint')
  }
  toggleActiveEditor() {
    this.emitter.emit('should-toggle-active-editor')
  }
  debug() {
    this.emitter.emit('should-debug')
  }
  onShouldLint(callback: Function): Disposable {
    return this.emitter.on('should-lint', callback)
  }
  onShouldDebug(callback: Function): Disposable {
    return this.emitter.on('should-debug', callback)
  }
  onShouldToggleActiveEditor(callback: Function): Disposable {
    return this.emitter.on('should-toggle-active-editor', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
