'use babel'

import {Emitter, CompositeDisposable} from 'atom'

export class Indie {
  constructor({name = null}) {
    this.name = name
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.subscriptions.add(this.emitter)
  }
  setMessages() {

  }
  deleteMessages() {

  }

  dispose() {
    this.subscriptions.dispose()
  }
}
