'use babel'

import {CompositeDisposable} from 'atom'

export default class UIRegistry {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.providers = new Set()
  }
  add(provider) {
    if (!this.providers.has(provider)) {
      this.providers.add(provider)
    }
  }
  delete(provider) {
    this.providers.delete(provider)
  }
  notify(messages) {
    this.providers.forEach(function(provider) {
      provider.update(messages)
    })
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
