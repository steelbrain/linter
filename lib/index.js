'use babel'

/* @flow */

import { Disposable } from 'atom'
import Linter from './main'
import type { State, UI } from './types'

module.exports = {
  state: null,
  instance: null,

  activate(state: State) {
    if (!atom.inSpecMode()) {
      require('atom-package-deps').install('linter')
    }
    this.instance = new Linter(state)
  },
  serialize(): State {
    return this.state
  },
  consumeLinter(linter: Linter): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      this.instance.addLinter(entry)
    }
    return new Disposable(() => {
      for (const entry of linters) {
        this.instance.deleteLinter(entry)
      }
    })
  },
  consumeLinterLegacy(linter: Linter): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      linter.name = linter.name || 'Unknown'
      this.instance.addLinter(entry, true)
    }
    return new Disposable(() => {
      for (const entry of linters) {
        this.instance.deleteLinter(entry)
      }
    })
  },
  consumeUI(ui: UI): Disposable {
    const uis = [].concat(ui)
    for (const entry of uis) {
      this.instance.addUI(entry)
    }
    return new Disposable(() => {
      for (const entry of uis) {
        this.instance.deleteUI(entry)
      }
    })
  },
  provideIndieLegacy(): Object {
    return {
      register: (options: Object) => this.instance.registryIndie.register(options, true),
    }
  },
  provideIndie(): Object {
    return {
      register: (options: Object) => this.instance.registryIndie.register(options, false),
    }
  },
  deactivate() {
    this.instance.dispose()
  },
}
