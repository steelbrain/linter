'use babel'

import {CompositeDisposable} from 'atom'
import Validate from './validate'

export default class UIRegistry {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.providers = new Map()
  }
  //add(provider, editors) {
  add(key, provider) {
    if (!this.providers.has(key)) {
      Validate.ui(key)
      this.subscriptions.add(provider)
      this.providers.set(key, provider)
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
