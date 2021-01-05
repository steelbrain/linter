import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'

import IndieDelegate from './indie-delegate'
import { indie as validateIndie } from './validate'
import type { Indie } from './types'

class IndieRegistry {
  emitter: Emitter = new Emitter()
  delegates: Set<IndieDelegate> = new Set()
  subscriptions: CompositeDisposable = new CompositeDisposable()

  constructor() {
    this.subscriptions.add(this.emitter)
  }
  // Public method
  register(config: Indie, version: 2): IndieDelegate {
    if (!validateIndie(config)) {
      throw new Error('Error registering Indie Linter')
    }
    const indieLinter = new IndieDelegate(config, version)
    this.delegates.add(indieLinter)
    indieLinter.onDidDestroy(() => {
      this.delegates.delete(indieLinter)
    })
    indieLinter.onDidUpdate(messages => {
      this.emitter.emit('did-update', { linter: indieLinter, messages })
    })
    this.emitter.emit('observe', indieLinter)

    return indieLinter
  }
  getProviders(): Array<IndieDelegate> {
    return Array.from(this.delegates)
  }
  observe(callback: (...args: Array<any>) => any): Disposable {
    this.delegates.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  onDidUpdate(callback: (...args: Array<any>) => any): Disposable {
    return this.emitter.on('did-update', callback)
  }
  dispose() {
    for (const entry of this.delegates) {
      entry.dispose()
    }
    this.subscriptions.dispose()
  }
}

export default IndieRegistry
