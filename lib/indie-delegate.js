/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'
import type { Message, Indie } from './types'

export default class IndieDelegate {
  name: string;
  scope: 'project';
  emitter: Emitter;
  subscriptions: CompositeDisposable;

  constructor({ name }: Indie) {
    this.name = name
    this.scope = 'project'
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }
  setMessages(messages: Array<Message>) {
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
