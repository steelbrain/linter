'use babel'

import {Emitter, CompositeDisposable} from 'atom'

export class IndieRegistry {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.subscriptions.add(this.emitter)
  }

  register() {

  }
  unregister() {

  }

  dispose() {
    this.subscriptions.dispose()
  }
}
