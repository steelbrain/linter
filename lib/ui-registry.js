'use babel'

import {CompositeDisposable} from 'atom'
import Validate from './validate'

export default class UIRegistry {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.providers = new Set()
  }
  add(ui) {
    if (!this.providers.has(ui)) {
      Validate.ui(ui)
      this.subscriptions.add(ui)
      this.providers.add(ui)
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
