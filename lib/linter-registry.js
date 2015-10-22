'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import Validate from './validate'
import Helpers from './helpers'

export default class LinterRegistry {
  constructor() {
    this.linters = new Set()
    this.locks = {
      Regular: new WeakSet(),
      Fly: new WeakSet()
    }

    this.subscriptions = new CompositeDisposable()
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
      Helpers.error(err)
    }
  }
  deleteLinter(linter) {
    if (this.linters.has(linter)) {
      linter.deactivated = true
      this.linters.delete(linter)
    }
  }
  lint({onChange, editorLinter}) {
    const editor = editorLinter.editor
    const lockKey = onChange ? 'Fly' : 'Regular'

    if (
      (onChange && !atom.config.get('linter.lintOnFly')) || // Lint-on-fly mismatch
      !editor.getPath()                                  || // Not saved anywhere yet
      editor !== atom.workspace.getActiveTextEditor()    || // Not active
      this.locks[lockKey].has(editorLinter)              || // Already linting
      (atom.config.get('linter.ignoreVCSIgnoredFiles') &&
        Helpers.isPathIgnored(editor.getPath()))            // Ignored by VCS
    ) {
      return
    }

    this.locks[lockKey].add(editorLinter)
    const scopes = editor.scopeDescriptorForBufferPosition(editor.getCursorBufferPosition()).scopes
    scopes.push('*')

    const promises = []
    this.linters.forEach(linter => {
      if (Helpers.shouldTriggerLinter(linter, onChange, scopes)) {
        promises.push(new Promise(function(resolve) {
          resolve(linter.lint(editor))
        }).then(results => {
          if (results) {
            this.emitter.emit('did-update-messages', {linter, messages: results, editor})
          }
        }, Helpers.error))
      }
    })
    return Promise.all(promises).then(() =>
      this.locks[lockKey].delete(editorLinter)
    )
  }
  onDidUpdateMessages(callback) {
    return this.emitter.on('did-update-messages', callback)
  }
  dispose() {
    this.linters.clear()
    this.subscriptions.dispose()
  }
}
