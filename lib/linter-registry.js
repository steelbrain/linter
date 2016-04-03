'use babel'

/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import { linter as validateLinter, messages as validateMessages } from './validate'
import { showError, isPathIgnored, shouldTriggerLinter } from './helpers'
import type { TextEditor, Disposable } from 'atom'
import type { Linter$Regular } from './types'

export default class LinterRegistry {
  emitter: Emitter;
  linters: Set<Linter$Regular>;
  ignoreGlob: string;
  ignoreVCS: boolean;
  lintPreviewTabs: boolean;
  subscriptions: CompositeDisposable;

  constructor() {
    this.emitter = new Emitter()
    this.linters = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(atom.config.observe('linter.ignoreGlob', ignoreGlob => {
      this.ignoreGlob = ignoreGlob
    }))
    this.subscriptions.add(atom.config.observe('linter.lintPreviewTabs', lintPreviewTabs => {
      this.lintPreviewTabs = lintPreviewTabs
    }))
    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', ignoreVCS => {
      this.ignoreVCS = ignoreVCS
    }))
    this.subscriptions.add(this.emitter)
  }
  getLinters(): Set<Linter$Regular> {
    return this.linters
  }
  hasLinter(linter: Linter$Regular): boolean {
    return this.linters.has(linter)
  }
  addLinter(linter: Linter$Regular) {
    try {
      validateLinter(linter)
      linter.deactivated = false
      this.linters.add(linter)
    } catch (err) {
      showError(err)
    }
  }
  deleteLinter(linter: Linter$Regular) {
    if (this.linters.has(linter)) {
      linter.deactivated = true
      this.linters.delete(linter)
    }
  }
  async lint({ onChange, editor } : { onChange: boolean, editor: TextEditor }): Promise<boolean> {
    const filePath = editor.getPath()

    if (
      (onChange && !atom.config.get('linter.lintOnFly'))                        || // Lint-on-fly mismatch
      !filePath                                                                 || // Not saved anywhere yet
      editor !== atom.workspace.getActiveTextEditor()                           || // Not active
      isPathIgnored(editor.getPath(), this.ignoreGlob, this.ignoreVCS)          || // Ignored by VCS or Glob
      (!this.lintPreviewTabs && editor.hasTerminatedPendingState === false)
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
  onDidUpdateMessages(callback: Function): Disposable {
    return this.emitter.on('did-update-messages', callback)
  }
  onDidBeginLinting(callback: Function): Disposable {
    return this.emitter.on('did-begin-linting', callback)
  }
  onDidFinishLinting(callback: Function): Disposable {
    return this.emitter.on('did-finish-linting', callback)
  }
  dispose() {
    this.linters.clear()
    this.subscriptions.dispose()
  }
}
