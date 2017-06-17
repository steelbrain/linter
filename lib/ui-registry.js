/* @flow */

import { CompositeDisposable } from 'atom'
import { ui as validateUI } from './validate'
import type { Linter, UI, MessagesPatch } from './types'

class UIRegistry {
  providers: Set<UI>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.providers = new Set()
    this.subscriptions = new CompositeDisposable()
  }
  add(ui: UI) {
    if (!this.providers.has(ui) && validateUI(ui)) {
      this.subscriptions.add(ui)
      this.providers.add(ui)
    }
  }
  delete(provider: UI) {
    if (this.providers.has(provider)) {
      provider.dispose()
      this.providers.delete(provider)
    }
  }
  getProviders(): Array<UI> {
    return Array.from(this.providers)
  }
  render(messages: MessagesPatch) {
    this.providers.forEach(function(provider) {
      provider.render(messages)
    })
  }
  didBeginLinting(linter: Linter, filePath: ?string = null) {
    this.providers.forEach(function(provider) {
      provider.didBeginLinting(linter, filePath)
    })
  }
  didFinishLinting(linter: Linter, filePath: ?string = null) {
    this.providers.forEach(function(provider) {
      provider.didFinishLinting(linter, filePath)
    })
  }
  dispose() {
    this.providers.clear()
    this.subscriptions.dispose()
  }
}

module.exports = UIRegistry
