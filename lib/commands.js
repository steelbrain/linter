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
      'linter:enable-provider': () => this.enableProvider(),
      'linter:disable-provider': () => this.disableProvider(),
    }))
  }
  lint() {
    this.emitter.emit('should-lint')
  }
  enableProvider() {
    console.log('add provider')
  }
  disableProvider() {
    console.log('disable provider')
  }
  toggleActiveEditor() {
    this.emitter.emit('should-toggle-active-editor')
  }
  onShouldToggleActiveEditor(callback: Function): Disposable {
    return this.emitter.on('should-toggle-active-editor', callback)
  }
  onShouldLint(callback: Function): Disposable {
    return this.emitter.on('should-lint', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
