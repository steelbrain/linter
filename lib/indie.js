'use babel'

/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Linter$Indie, Linter$Message } from './types'
import type { Disposable } from 'atom'

export default class Indie {
  name: ?string;
  scope: 'project';
  emitter: Emitter;
  subscriptions: CompositeDisposable;

  constructor({ name }: Linter$Indie) {
    this.name = name
    this.scope = 'project'
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }
  setMessages(messages: Array<Linter$Message>) {
    this.emitter.emit('did-update-messages', messages)
  }
  deleteMessages() {
    this.emitter.emit('did-update-messages', [])
  }
  dispose() {
    this.emitter.emit('did-destroy')
    this.subscriptions.dispose()
  }

  // Private Methods
  onDidUpdateMessages(callback: Function): Disposable {
    return this.emitter.on('did-update-messages', callback)
  }
  onDidDestroy(callback: Function): Disposable {
    return this.emitter.on('did-destroy', callback)
  }
}
