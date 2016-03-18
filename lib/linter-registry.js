'use babel'

import { Emitter, CompositeDisposable } from 'atom'
import { linter as validateLinter, messages as validateMessages } from './validate'
import { showError, isPathIgnored, shouldTriggerLinter } from './helpers'

export default class LinterRegistry {
  constructor() {
    this.linters = new Set()
    this.number = 0

    this.subscriptions = new CompositeDisposable()
    this.subscriptions.add(atom.config.observe('linter.ignoreGlob', ignoreGlob => {
      this.ignoreGlob = ignoreGlob
    }))
    this.emitter = new Emitter()
    this.subscriptions.add(this.emitter)
  }
  getLinters() {
    return this.linters
  }
  hasLinter(linter) {
    return this.linters.has(linter)
  }
  addLinter(linter) {
    try {
      validateLinter(linter)
      linter.deactivated = false
      this.linters.add(linter)
    } catch (err) {
      showError(err)
    }
  }
  deleteLinter(linter) {
    if (this.linters.has(linter)) {
      linter.deactivated = true
      this.linters.delete(linter)
    }
  }
  async lint({ onChange, editor }): boolean {
    const filePath = editor.getPath()

    if (
      (onChange && !atom.config.get('linter.lintOnFly'))        || // Lint-on-fly mismatch
      !filePath                                                 || // Not saved anywhere yet
      editor !== atom.workspace.getActiveTextEditor()           || // Not active
      isPathIgnored(editor.getPath(), this.ignoreGlob)             // Ignored by VCS or Glob
    ) {
      return false
    }

    const scopes = editor.scopeDescriptorForBufferPosition(editor.getCursorBufferPosition()).getScopesArray()
    scopes.push('*')

    const promises = []
    this.linters.forEach(linter => {
      if (shouldTriggerLinter(linter, onChange, scopes)) {
        const number = linter.number = (linter.number || 0) + 1
        this.emitter.emit('did-begin-linting', { number, linter })
        promises.push(new Promise(function(resolve) {
          resolve(linter.lint(editor))
        }).then(messages => {
          this.emitter.emit('did-finish-linting', { number, linter })
          if (messages && linter.number === number && !linter.deactivated) {
            const buffer = linter.scope === 'project' ? null : editor.getBuffer()
            if (!buffer || buffer.isAlive()) {
              if (atom.inDevMode()) {
                validateMessages(messages)
              }
              this.emitter.emit('did-update-messages', { messages, linter, buffer })
            }
          }
        }, showError))
      }
    })

    await Promise.all(promises)
    return true
  }
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }
  onDidBeginLinting(callback) {
    return this.emitter.on('did-begin-linting', callback)
  }
  onDidFinishLinting(callback) {
    return this.emitter.on('did-finish-linting', callback)
  }
  dispose() {
    this.linters.clear()
    this.subscriptions.dispose()
  }
}
