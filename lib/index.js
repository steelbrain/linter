/* @flow */

import { CompositeDisposable, Disposable } from 'atom'

import Linter from './main'
import type { UI, Linter as LinterProvider, State } from './types'

// Internal variables
let instance

const idleCallbacks = new Set()

export default {
  activate(givenState: ?State) {
    const state = givenState || {}

    this.subscriptions = new CompositeDisposable()

    instance = new Linter(state)
    this.subscriptions.add(instance)

    const linterDepsCallback = window.requestIdleCallback(function linterDepsInstall() {
      idleCallbacks.delete(linterDepsCallback)
      if (!atom.inSpecMode()) {
        // eslint-disable-next-line global-require
        require('atom-package-deps').install('linter', true)
      }
    })
    idleCallbacks.add(linterDepsCallback)
  },
  consumeLinter(linter: LinterProvider): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      instance.addLinter(entry)
    }
    return new Disposable(() => {
      for (const entry of linters) {
        instance.deleteLinter(entry)
      }
    })
  },
  consumeLinterLegacy(linter: LinterProvider): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      linter.name = linter.name || 'Unknown'
      linter.lintOnFly = Boolean(linter.lintOnFly)
      instance.addLinter(entry, true)
    }
    return new Disposable(() => {
      for (const entry of linters) {
        instance.deleteLinter(entry)
      }
    })
  },
  consumeUI(ui: UI): Disposable {
    const uis = [].concat(ui)
    for (const entry of uis) {
      instance.addUI(entry)
    }
    return new Disposable(() => {
      for (const entry of uis) {
        instance.deleteUI(entry)
      }
    })
  },
  provideIndie(): Object {
    return indie =>
      instance.addIndie(indie)
  },
  provideIndieLegacy(): Object {
    return {
      register: indie => instance.addLegacyIndie(indie),
    }
  },
  serialize(): Object {
    instance.registryMessagesInit()
    return {
      messages: instance.registryMessages.serialize(),
    }
  },
  deactivate() {
    idleCallbacks.forEach(callbackID => window.cancelIdleCallback(callbackID))
    idleCallbacks.clear()
    this.subscriptions.dispose()
  },
}
