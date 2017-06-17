/* @flow */
/* eslint-disable import/no-duplicates */

import { Emitter, CompositeDisposable } from 'atom'
import type { TextEditor, Disposable } from 'atom'

import * as Helpers from './helpers'
import * as Validate from './validate'
import { $version, $activated, $requestLatest, $requestLastReceived } from './helpers'
import type { Linter } from './types'

class LinterRegistry {
  emitter: Emitter;
  linters: Set<Linter>;
  lintOnChange: boolean;
  ignoreVCS: boolean;
  ignoreGlob: string;
  lintPreviewTabs: boolean;
  subscriptions: CompositeDisposable;
  disabledProviders: Array<string>;

  constructor() {
    this.emitter = new Emitter()
    this.linters = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(atom.config.observe('linter.lintOnChange', (lintOnChange) => {
      this.lintOnChange = lintOnChange
    }))
    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', (ignoreVCS) => {
      this.ignoreVCS = ignoreVCS
    }))
    this.subscriptions.add(atom.config.observe('linter.ignoreGlob', (ignoreGlob) => {
      this.ignoreGlob = ignoreGlob
    }))
    this.subscriptions.add(atom.config.observe('linter.lintPreviewTabs', (lintPreviewTabs) => {
      this.lintPreviewTabs = lintPreviewTabs
    }))
    this.subscriptions.add(atom.config.observe('linter.disabledProviders', (disabledProviders) => {
      this.disabledProviders = disabledProviders
    }))
    this.subscriptions.add(this.emitter)
  }
  hasLinter(linter: Linter): boolean {
    return this.linters.has(linter)
  }
  addLinter(linter: Linter, legacy: boolean = false) {
    const version = legacy ? 1 : 2
    if (!Validate.linter(linter, version)) {
      return
    }
    linter[$activated] = true
    if (typeof linter[$requestLatest] === 'undefined') {
      linter[$requestLatest] = 0
    }
    if (typeof linter[$requestLastReceived] === 'undefined') {
      linter[$requestLastReceived] = 0
    }
    linter[$version] = version
    this.linters.add(linter)
  }
  getProviders(): Array<Linter> {
    return Array.from(this.linters)
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
      (onChange && !this.lintOnChange) ||                                                       // Lint-on-change mismatch
      !filePath ||                                                                              // Not saved anywhere yet
      Helpers.isPathIgnored(editor.getPath(), this.ignoreGlob, this.ignoreVCS) ||               // Ignored by VCS or Glob
      (!this.lintPreviewTabs && atom.workspace.getActivePane().getPendingItem() === editor)     // Ignore Preview tabs
    ) {
      return false
    }

    const scopes = Helpers.getEditorCursorScopes(editor)

    const promises = []
    for (const linter of this.linters) {
      if (!Helpers.shouldTriggerLinter(linter, onChange, scopes)) {
        continue
      }
      if (this.disabledProviders.includes(linter.name)) {
        continue
      }
      const number = ++linter[$requestLatest]
      const statusBuffer = linter.scope === 'file' ? editor.getBuffer() : null
      const statusFilePath = linter.scope === 'file' ? filePath : null

      this.emitter.emit('did-begin-linting', { number, linter, filePath: statusFilePath })
      promises.push(new Promise(function(resolve) {
        // $FlowIgnore: Type too complex, duh
        resolve(linter.lint(editor))
      }).then((messages) => {
        this.emitter.emit('did-finish-linting', { number, linter, filePath: statusFilePath })
        if (linter[$requestLastReceived] >= number || !linter[$activated] || (statusBuffer && !statusBuffer.isAlive())) {
          return
        }
        linter[$requestLastReceived] = number
        if (statusBuffer && !statusBuffer.isAlive()) {
          return
        }

        if (messages === null) {
          // NOTE: Do NOT update the messages when providers return null
          return
        }

        let validity = true
        // NOTE: We are calling it when results are not an array to show a nice notification
        if (atom.inDevMode() || !Array.isArray(messages)) {
          validity = linter[$version] === 2 ? Validate.messages(linter.name, messages) : Validate.messagesLegacy(linter.name, messages)
        }
        if (!validity) {
          return
        }

        if (linter[$version] === 2) {
          Helpers.normalizeMessages(linter.name, messages)
        } else {
          Helpers.normalizeMessagesLegacy(linter.name, messages)
        }
        this.emitter.emit('did-update-messages', { messages, linter, buffer: statusBuffer })
      }, (error) => {
        this.emitter.emit('did-finish-linting', { number, linter, filePath: statusFilePath })
        atom.notifications.addError(`[Linter] Error running ${linter.name}`, {
          detail: 'See Console for more info. (Open View -> Developer -> Toggle Developer Tools)',
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

module.exports = LinterRegistry
