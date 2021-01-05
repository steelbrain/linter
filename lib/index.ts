import { CompositeDisposable, Disposable } from 'atom'

import Linter from './main'
import type { UI, Linter as LinterProvider, Indie } from './types'

// Internal variables
let instance: Linter
let subscriptions: CompositeDisposable

export function activate() {
  subscriptions = new CompositeDisposable()

  instance = new Linter()
  subscriptions.add(
    instance,
    atom.packages.onDidActivateInitialPackages(function () {
      if (!atom.inSpecMode()) {
        require('atom-package-deps').install('linter', true)
      }
    }),
  )
}
export function consumeLinter(linter: LinterProvider | Array<LinterProvider>): Disposable {
  const linters = Array.isArray(linter) ? linter : [linter]

  for (const entry of linters) {
    instance.addLinter(entry)
  }
  return new Disposable(() => {
    for (const entry of linters) {
      instance.deleteLinter(entry)
    }
  })
}
export function consumeUI(ui: UI | Array<UI>): Disposable {
  const uis = Array.isArray(ui) ? ui : [ui]

  for (const entry of uis) {
    instance.addUI(entry)
  }
  return new Disposable(() => {
    for (const entry of uis) {
      instance.deleteUI(entry)
    }
  })
}
export function provideIndie() {
  return (indie: Indie) => instance.addIndie(indie)
}
export function deactivate() {
  subscriptions.dispose()
}
