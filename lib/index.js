'use babel'

/* @flow */

import { Disposable } from 'atom'
import type IndieRegistry from './indie-registry'
import type { Linter$State, Linter$Linter, Linter$UI } from './types'

module.exports = {
  state: null,
  instance: null,

  activate(state: Linter$State) {
    if (!atom.inSpecMode()) {
      require('atom-package-deps').install('linter')
    }

    const Linter = require('./main')
    this.instance = new Linter(state)
  },
  serialize(): Linter$State {
    return this.state
  },
  consumeLinter(linter: Linter$Linter): Disposable {
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
  consumeUI(ui: Linter$UI): Disposable {
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
  provideIndie(): IndieRegistry {
    return this.instance.registryIndie
  },
  deactivate() {
    this.instance.dispose()
  }
}
