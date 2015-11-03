'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import Validate from './validate'
import {Indie} from './indie'

export class IndieRegistry {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.indieLinters = new Set()
    this.subscriptions.add(this.emitter)
  }

  register(linter) {
    Validate.linter(linter, true)
    const indieLinter = new Indie(linter)

    this.subscriptions.add(indieLinter)
    this.indieLinters.add(indieLinter)

    indieLinter.onDidDestroy(() => {
      this.indieLinters.delete(indieLinter)
    })

    return indieLinter
  }
  unregister(indieLinter) {
    if (this.indieLinters.has(indieLinter)) {
      indieLinter.dispose()
    }
  }

  dispose() {
    this.subscriptions.dispose()
  }
}
