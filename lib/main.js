/* @flow */

import arrayUnique from 'lodash.uniq'
import { CompositeDisposable } from 'atom'

import manifest from '../package.json'
import Commands from './commands'
import UIRegistry from './ui-registry'
import ToggleView from './toggle-view'
import IndieRegistry from './indie-registry'
import LinterRegistry from './linter-registry'
import MessageRegistry from './message-registry'
import EditorsRegistry from './editor-registry'
import * as Helpers from './helpers'
import type { UI, Linter as LinterProvider } from './types'

class Linter {
  commands: Commands;
  registryUI: UIRegistry;
  registryIndie: IndieRegistry;
  registryEditors: EditorsRegistry;
  registryLinters: LinterRegistry;
  registryMessages: MessageRegistry;
  subscriptions: CompositeDisposable;

  constructor() {
    this.commands = new Commands()
    this.registryUI = new UIRegistry()
    this.registryIndie = new IndieRegistry()
    this.registryEditors = new EditorsRegistry()
    this.registryLinters = new LinterRegistry()
    this.registryMessages = new MessageRegistry()

    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.commands)
    this.subscriptions.add(this.registryUI)
    this.subscriptions.add(this.registryIndie)
    this.subscriptions.add(this.registryMessages)
    this.subscriptions.add(this.registryEditors)
    this.subscriptions.add(this.registryLinters)

    this.commands.onShouldLint(() => {
      const editorLinter = this.registryEditors.get(atom.workspace.getActiveTextEditor())
      if (editorLinter) {
        editorLinter.lint()
      }
    })
    this.commands.onShouldToggleActiveEditor(() => {
      const textEditor = atom.workspace.getActiveTextEditor()
      const editor = this.registryEditors.get(textEditor)
      if (editor) {
        editor.dispose()
      } else if (textEditor) {
        this.registryEditors.createFromTextEditor(textEditor)
      }
    })
    // NOTE: ESLint arrow-parens rule has a bug
    // eslint-disable-next-line arrow-parens
    this.commands.onShouldDebug(async () => {
      const linters = this.registryLinters.getLinters()
      const configFile = await Helpers.getConfigFile()
      const textEditor = atom.workspace.getActiveTextEditor()
      const textEditorScopes = Helpers.getEditorCursorScopes(textEditor)

      const allLinters = linters
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(linter => `  - ${linter.name}`).join('\n')
      const matchingLinters = linters
        .filter(linter => Helpers.shouldTriggerLinter(linter, false, textEditorScopes))
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(linter => `  - ${linter.name}`).join('\n')
      const humanizedScopes = textEditorScopes
        .map(scope => `  - ${scope}`).join('\n')
      const disabledLinters = (await configFile.get('disabled'))
        .map(linter => `  - ${linter}`).join('\n')

      atom.notifications.addInfo('Linter Debug Info', {
        detail: [
          `Platform: ${process.platform}`,
          `Atom Version: ${atom.getVersion()}`,
          `Linter Version: ${manifest.version}`,
          `All Linter Providers: \n${allLinters}`,
          `Matching Linter Providers: \n${matchingLinters}`,
          `Disabled Linter Providers; \n${disabledLinters}`,
          `Current File scopes: \n${humanizedScopes}`,
        ].join('\n'),
        dismissable: true,
      })
    })
    this.commands.onShouldToggleLinter((action) => {
      const toggleView = new ToggleView(action, arrayUnique(this.registryLinters.getLinters().map(linter => linter.name)))
      toggleView.onDidDispose(() => {
        this.subscriptions.remove(toggleView)
      })
      toggleView.onDidDisable((name) => {
        const linter = this.registryLinters.getLinters().find(entry => entry.name === name)
        if (linter) {
          this.registryMessages.deleteByLinter(linter)
        }
      })
      toggleView.show()
      this.subscriptions.add(toggleView)
    })
    this.registryIndie.observe((indieLinter) => {
      indieLinter.onDidDestroy(() => {
        this.registryMessages.deleteByLinter(indieLinter)
      })
    })
    this.registryEditors.observe((editorLinter) => {
      editorLinter.onShouldLint((onChange) => {
        this.registryLinters.lint({ onChange, editor: editorLinter.getEditor() })
      })
      editorLinter.onDidDestroy(() => {
        this.registryMessages.deleteByBuffer(editorLinter.getEditor().getBuffer())
      })
    })
    this.registryIndie.onDidUpdate(({ linter, messages }) => {
      this.registryMessages.set({ linter, messages, buffer: null })
    })
    this.registryLinters.onDidUpdateMessages(({ linter, messages, buffer }) => {
      this.registryMessages.set({ linter, messages, buffer })
    })
    this.registryLinters.onDidBeginLinting(({ linter, filePath }) => {
      this.registryUI.didBeginLinting(linter, filePath)
    })
    this.registryLinters.onDidFinishLinting(({ linter, filePath }) => {
      this.registryUI.didFinishLinting(linter, filePath)
    })
    this.registryMessages.onDidUpdateMessages((difference) => {
      this.registryUI.render(difference)
    })

    this.registryEditors.activate()

    setTimeout(() => {
      // NOTE: Atom triggers this on boot so wait a while
      if (!this.subscriptions.disposed) {
        this.subscriptions.add(atom.project.onDidChangePaths(() => {
          this.commands.lint()
        }))
      }
    }, 100)
  }
  dispose() {
    this.subscriptions.dispose()
  }

  // API methods for providing/consuming services
  addUI(ui: UI) {
    this.registryUI.add(ui)
  }
  deleteUI(ui: UI) {
    this.registryUI.delete(ui)
  }
  addLinter(linter: LinterProvider, legacy: boolean = false) {
    this.registryLinters.addLinter(linter, legacy)
  }
  deleteLinter(linter: LinterProvider) {
    this.registryLinters.deleteLinter(linter)
    this.registryMessages.deleteByLinter(linter)
  }
}

module.exports = Linter
