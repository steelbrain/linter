'use babel'

import {Emitter, CompositeDisposable} from 'atom'

export class Indie {
  constructor({name = null}) {
    this.name = name
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

  dispose() {
    this.subscriptions.dispose()
  }
}
