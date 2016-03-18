'use babel'

/* @flow */

import { CompositeDisposable } from 'atom'
import { ui as validateUI } from './validate'
import type { Linter$UI, Linter$Difference, Linter$Regular } from './types'

export default class UIRegistry {
  providers: Set<Linter$UI>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.providers = new Set()
    this.subscriptions = new CompositeDisposable()
  }
  add(ui: Linter$UI) {
    if (!this.providers.has(ui)) {
      validateUI(ui)
      this.subscriptions.add(ui)
      this.providers.add(ui)
      ui.activate()
    }
  }
  delete(provider: Linter$UI) {
    if (this.providers.has(provider)) {
      provider.dispose()
      this.providers.delete(provider)
    }
  }
  didCalculateMessages(messages: Linter$Difference) {
    this.providers.forEach(function(provider) {
      provider.didCalculateMessages(messages)
    })
  }
  didBeginLinting(linter: Linter$Regular, filePath: string) {
    this.providers.forEach(function(provider) {
      provider.didBeginLinting(linter, filePath)
    })
  }
  didFinishLinting(linter: Linter$Regular, filePath: string) {
    this.providers.forEach(function(provider) {
      provider.didFinishLinting(linter, filePath)
    })
  }
  dispose() {
    this.providers.clear()
    this.subscriptions.dispose()
  }
}
