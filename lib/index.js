'use babel'

/* @flow */

import { Disposable } from 'atom'
import type IndieRegistry from './indie-registry'
import type { State, Linter, UI } from './types'

module.exports = {
  state: null,
  instance: null,

  activate(state: State) {
    if (!atom.inSpecMode()) {
      require('atom-package-deps').install('linter')
    }

    const LinterMain = require('./main')
    this.instance = new LinterMain(state)
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
  consumeLinterOld(linter: Linter): Disposable {
    console.log('old linter', linter)
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
  provideIndie(): IndieRegistry {
    return this.instance.registryIndie
  },
  deactivate() {
    this.instance.dispose()
  }
}
