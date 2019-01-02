/* @flow */

import { CompositeDisposable, Disposable } from 'atom'

import Linter from './main'
import type { UI, Linter as LinterProvider } from './types'

// Internal variables
let instance

export default {
  activate() {
    this.subscriptions = new CompositeDisposable()

    instance = new Linter()
    this.subscriptions.add(instance)

    this.subscriptions.add(
      atom.packages.onDidActivateInitialPackages(function() {
        if (!atom.inSpecMode()) {
          require('atom-package-deps').install('linter', true)
        }
      }),
    )
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
    return indie => instance.addIndie(indie)
  },
  deactivate() {
    this.subscriptions.dispose()
  },
}
