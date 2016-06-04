'use babel'

/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import { indie as validateIndie, messages as validateMessages } from './validate'
import Indie from './indie'
import type { Disposable } from 'atom'
import type { IndieConfig } from './types'

export default class IndieRegistry {
  emitter: Emitter;
  indieLinters: Set<Indie>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.emitter = new Emitter()
    this.indieLinters = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }

  register(config: IndieConfig): Indie {
    if (!validateIndie(config)) {
      throw new Error('Error registering Indie Linter')
    }
    const indieLinter = new Indie(config)

    this.subscriptions.add(indieLinter)
    this.indieLinters.add(indieLinter)

    indieLinter.onDidDestroy(() => {
      this.indieLinters.delete(indieLinter)
      this.subscriptions.remove(indieLinter)
    })
    indieLinter.onDidUpdateMessages(messages => {
      const validity = atom.inDevMode() ? validateMessages(indieLinter.name, messages) : true
      if (validity) {
        this.emitter.emit('did-update-messages', { linter: indieLinter, messages })
      }
    })
    this.emitter.emit('observe', indieLinter)

    return indieLinter
  }
  has(indieLinter: Indie): boolean {
    return this.indieLinters.has(indieLinter)
  }

  // Private methods
  observe(callback: Function): Disposable {
    this.indieLinters.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  onDidUpdateMessages(callback: Function): Disposable {
    return this.emitter.on('did-update-messages', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
