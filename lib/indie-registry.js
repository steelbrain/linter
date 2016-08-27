/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'

import IndieDelegate from './indie-delegate'
import { normalizeMessages } from './helpers'
import { indie as validateIndie, messages as validateMessages } from './validate'
import type { Indie } from './types'

export default class IndieRegistry {
  emitter: Emitter;
  indieLinters: Set<IndieDelegate>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.emitter = new Emitter()
    this.indieLinters = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }

  register(config: Indie): IndieDelegate {
    if (!validateIndie(config)) {
      throw new Error('Error registering Indie Linter')
    }
    const indieLinter = new IndieDelegate(config)

    this.subscriptions.add(indieLinter)
    this.indieLinters.add(indieLinter)

    indieLinter.onDidDestroy(() => {
      this.indieLinters.delete(indieLinter)
      this.subscriptions.remove(indieLinter)
    })
    indieLinter.onDidUpdate(messages => {
      let validity = true
      if (atom.inDevMode()) {
        validity = validateMessages(indieLinter.name, messages)
      }
      if (validity) {
        normalizeMessages(indieLinter.name, messages)
        this.emitter.emit('did-update', { linter: indieLinter, messages })
      }
    })
    this.emitter.emit('observe', indieLinter)

    return indieLinter
  }
  observe(callback: Function): Disposable {
    this.indieLinters.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  onDidUpdate(callback: Function): Disposable {
    return this.emitter.on('did-update', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
