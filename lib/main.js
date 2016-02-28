'use babel'

import { Disposable } from 'atom'

module.exports = {
  state: null,
  instance: null,

  activate(state) {
    require('atom-package-deps').install('linter')

    const linter = require('./linter')
    this.instance = new linter(state)
  },
  serialize() {
    return this.state
  },
  consumeLinter(linter) {
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
  consumeUI(ui) {
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
  provideLinter() {
    return this.instance
  },
  provideIndie() {
    return this.instance.indieLinters
  },
  provideIntentions() {
    return []
  },
  deactivate() {
    this.instance.dispose()
  }
}
