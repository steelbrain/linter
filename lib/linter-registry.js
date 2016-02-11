'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import Validate from './validate'
import {showError, isPathIgnored, shouldTriggerLinter} from './helpers'

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
      Validate.linter(linter)
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
  async lint({onChange, editorLinter}) {
    const editor = editorLinter.editor
    const filePath = editor.getPath()
    const number = ++this.number

    if (
      (onChange && !atom.config.get('linter.lintOnFly'))        || // Lint-on-fly mismatch
      !filePath                                                 || // Not saved anywhere yet
      editor !== atom.workspace.getActiveTextEditor()           || // Not active
      isPathIgnored(editor.getPath(), this.ignoreGlob)             // Ignored by VCS or Glob
    ) {
      return
    }

    const scopes = editor.scopeDescriptorForBufferPosition(editor.getCursorBufferPosition()).getScopesArray()
    scopes.push('*')

    const promises = []
    this.linters.forEach(linter => {
      if (shouldTriggerLinter(linter, onChange, scopes)) {
        this.emitter.emit('did-begin-linting', {number, linter})
        promises.push(new Promise(function(resolve) {
          resolve(linter.lint(editor))
        }).then(messages => {
          this.emitter.emit('did-finish-linting', {number, linter})
          if (messages && this.number === number) {
            const buffer = linter.scope === 'project' ? null : editor.getBuffer()
            this.emitter.emit('did-update-messages', {messages, linter, buffer})
          }
        }, showError))
      }
    })

    await Promise.all(promises)
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
