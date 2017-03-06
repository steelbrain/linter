/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import type { Disposable } from 'atom'

export default class Commands {
  emitter: Emitter;
  subscriptions: CompositeDisposable;

  constructor() {
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'linter:enable-linter': () => this.enableLinter(),
      'linter:disable-linter': () => this.disableLinter(),
    }))
    this.subscriptions.add(atom.commands.add('atom-text-editor:not([mini])', {
      'linter:lint': () => this.lint(),
      'linter:debug': () => this.debug(),
      'linter:toggle-active-editor': () => this.toggleActiveEditor(),
    }))
  }
  lint() {
    this.emitter.emit('should-lint')
  }
  debug() {
    this.emitter.emit('should-debug')
  }
  enableLinter() {
    this.emitter.emit('should-toggle-linter', 'enable')
  }
  disableLinter() {
    this.emitter.emit('should-toggle-linter', 'disable')
  }
  toggleActiveEditor() {
    this.emitter.emit('should-toggle-active-editor')
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
  onShouldToggleLinter(callback: Function): Disposable {
    return this.emitter.on('should-toggle-linter', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
