'use babel'

import {Emitter, CompositeDisposable} from 'atom'

export class Indie {
  constructor({name = null, scope}) {
    this.name = name
    this.scope = scope
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.subscriptions.add(this.emitter)
  }
  setMessages() {
    if (this.scope === 'file') {
      // file, messages
    } else {
      // messages only
    }
  }
  deleteMessages() {
    if (this.scope === 'file') {
      // file
    } else {
      // delete all
    }
  }

  dispose() {
    this.subscriptions.dispose()
  }
}
