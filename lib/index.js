/* @flow */

import { Disposable } from 'atom'
import Linter from './main'
import Greeter from './greeter'
import type { State, UI, Linter as LinterProvider } from './types'

export default {
  greeter: null,
  instance: null,
  activate(state: State) {
    if (!atom.inSpecMode()) {
      // eslint-disable-next-line global-require
      require('atom-package-deps').install('linter', true)
    }
    this.greeter = new Greeter()
    this.instance = new Linter(state)

    this.greeter.activate().catch(e => console.error('[Linter-UI-Default] Error', e))
  },
  serialize(): State {
    return this.instance.state
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
  consumeLinterLegacy(linter: LinterProvider): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      linter.name = linter.name || 'Unknown'
      linter.lintOnFly = Boolean(linter.lintOnFly)
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
  provideIndie(): Object {
    return indie =>
      this.instance.registryIndie.register(indie)
  },
  deactivate() {
    this.instance.dispose()
    this.greeter.dispose()
  },
}
