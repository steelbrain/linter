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
      if (arguments.length !== 2) {
        throw new Error(`Expected two arguments for file scoped linter, got ${arguments.length}`)
      }
      // file, messages
    } else {
      if (arguments.length !== 1) {
        throw new Error(`Expected one argument for project scoped linter, got ${arguments.length}`)
      }
      // messages only
    }
  }
  deleteMessages() {
    if (this.scope === 'file') {
      if (arguments.length !== 1) {
        throw new Error(`Expected one argument for file scoped linter, got ${arguments.length}`)
      }
      // file
    } else {
      // delete all
    }
  }

  dispose() {
    this.subscriptions.dispose()
  }
}
