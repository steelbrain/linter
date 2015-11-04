'use babel'

import {Emitter, CompositeDisposable} from 'atom'

export default class Indie {
  constructor({name}) {
    this.name = name
    this.scope = 'project'
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.subscriptions.add(this.emitter)
  }
  setMessages(messages) {
    this.emitter.emit('did-update-messages', messages)
  }
  deleteMessages() {
    this.emitter.emit('did-update-messages', [])
  }

  // Private Method
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }
  // Private Method
  onDidDestroy(callback) {
    return this.emitter.on('did-destroy', callback)
  }

  dispose() {
    this.emitter.emit('did-destroy')
    this.subscriptions.dispose()
  }
}
