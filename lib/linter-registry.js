'use babel'

/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import { linter as validateLinter, messages as validateMessages } from './validate'
import { normalizeMessages, isPathIgnored, shouldTriggerLinter, $activated, $requestLatest, $requestLastReceived } from './helpers'
import type { TextEditor, Disposable } from 'atom'
import type { Linter } from './types'

export default class LinterRegistry {
  emitter: Emitter;
  linters: Set<Linter>;
  lintOnFly: boolean;
  ignoreVCS: boolean;
  ignoreGlob: string;
  lintPreviewTabs: boolean;
  subscriptions: CompositeDisposable;

  constructor() {
    this.emitter = new Emitter()
    this.linters = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(atom.config.observe('linter.lintOnFly', lintOnFly => {
      this.lintOnFly = lintOnFly
    }))
    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', ignoreVCS => {
      this.ignoreVCS = ignoreVCS
    }))
    this.subscriptions.add(atom.config.observe('linter.ignoreGlob', ignoreGlob => {
      this.ignoreGlob = ignoreGlob
    }))
    this.subscriptions.add(atom.config.observe('linter.lintPreviewTabs', lintPreviewTabs => {
      this.lintPreviewTabs = lintPreviewTabs
    }))
    this.subscriptions.add(this.emitter)
  }
  hasLinter(linter: Linter): boolean {
    return this.linters.has(linter)
  }
  addLinter(linter: Linter) {
    if (!validateLinter(linter)) {
      return
    }
    linter[$activated] = true
    if (typeof linter[$requestLatest] === 'undefined') {
      linter[$requestLatest] = 0
    }
    if (typeof linter[$requestLastReceived] === 'undefined') {
      linter[$requestLastReceived] = 0
    }
    this.linters.add(linter)
  }
  deleteLinter(linter: Linter) {
    if (!this.linters.has(linter)) {
      return
    }
    linter[$activated] = false
    this.linters.delete(linter)
  }
  async lint({ onChange, editor } : { onChange: boolean, editor: TextEditor }): Promise<boolean> {
    const filePath = editor.getPath()

    if (
      (onChange && !this.lintOnFly)                                             || // Lint-on-fly mismatch
      !filePath                                                                 || // Not saved anywhere yet
      editor !== atom.workspace.getActiveTextEditor()                           || // Not active
      isPathIgnored(editor.getPath(), this.ignoreGlob, this.ignoreVCS)          || // Ignored by VCS or Glob
      (!this.lintPreviewTabs && editor.hasTerminatedPendingState === false)        // Ignore Preview tabs
    ) {
      return false
    }

    const scopes = editor.scopeDescriptorForBufferPosition(editor.getCursorBufferPosition()).getScopesArray()
    scopes.push('*')

    const promises = []
    for (const linter of this.linters) {
      if (!shouldTriggerLinter(linter, onChange, scopes)) {
        continue
      }
      const number = ++linter[$requestLatest]
      this.emitter.emit('did-begin-linting', { number, linter })
      promises.push(new Promise(function(resolve) {
        resolve(linter.lint(editor))
      }).then(messages => {
        this.emitter.emit('did-finish-linting', { number, linter })
        if (Array.isArray(messages) && linter[$requestLastReceived] < number && linter[$activated]) {
          linter[$requestLastReceived] = number
          const buffer = linter.scope === 'project' ? null : editor.getBuffer()
          if (!buffer || buffer.isAlive()) {
            const validity = atom.inDevMode() ? validateMessages(linter.name, messages) : true
            if (validity) {
              normalizeMessages(linter.name, messages)
              this.emitter.emit('did-update-messages', { messages, linter, buffer })
            }
          }
        }
      }, function(error) {
        atom.notifications.addError(`[Linter] Error running ${linter.name}`, {
          detail: 'See console for more info'
        })
        console.error(`[Linter] Error running ${linter.name}`, error)
      }))
    }

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
