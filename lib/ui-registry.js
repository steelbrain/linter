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
      ui.activate()
    }
  }
  delete(provider) {
    this.providers.delete(provider)
  }
  didCalculateMessages(messages) {
    this.providers.forEach(function(provider) {
      provider.didCalculateMessages(messages)
    })
  }
  didBeginLinting(linter, filePath /* = null */) {
    this.providers.forEach(function(provider) {
      provider.didBeginLinting(linter, filePath)
    })
  }
  didFinishLinting(linter, filePath /* = null */) {
    this.providers.forEach(function(provider) {
      provider.didFinishLinting(linter, filePath)
    })
  }
  dispose() {
    this.providers.clear()
    this.subscriptions.dispose()
  }
}
