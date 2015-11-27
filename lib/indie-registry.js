'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import Validate from './validate'
import Indie from './indie'

export default class IndieRegistry {
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
    indieLinter.onDidUpdateMessages(messages => {
      this.emitter.emit('did-update-messages', {linter: indieLinter, messages})
    })
    this.emitter.emit('observe', indieLinter)

    return indieLinter
  }
  has(indieLinter) {
    return this.indieLinters.has(indieLinter)
  }
  unregister(indieLinter) {
    if (this.indieLinters.has(indieLinter)) {
      indieLinter.dispose()
    }
  }

  // Private method
  observe(callback) {
    this.indieLinters.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  // Private method
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }

  dispose() {
    this.subscriptions.dispose()
  }
}
