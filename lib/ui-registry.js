'use babel'

import {CompositeDisposable} from 'atom'
import Validate from './validate'

export default class UIRegistry {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.providers = new Map()
  }
  add(provider, editors) {
    if (!this.providers.has(provider)) {
      Validate.ui(provider)
      const inst = new provider(editors)
      this.subscriptions.add(inst)
      this.providers.set(provider, inst)
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
    this.providers.clear()
    this.subscriptions.dispose()
  }
}
