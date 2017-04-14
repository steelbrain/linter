/* @flow */

import { CompositeDisposable } from 'atom'

import Commands from './commands'
import type { UI, Linter as LinterProvider } from './types'

let Helpers
let manifest
let ToggleView
let UIRegistry
let arrayUnique
let IndieRegistry
let LinterRegistry
let EditorsRegistry
let MessageRegistry

class Linter {
  commands: Commands;
  registryUI: UIRegistry;
  registryIndie: IndieRegistry;
  registryEditors: EditorsRegistry;
  registryLinters: LinterRegistry;
  registryMessages: MessageRegistry;
  subscriptions: CompositeDisposable;
  idleCallbacks: Set<number>;

  constructor() {
    this.idleCallbacks = new Set()
    this.subscriptions = new CompositeDisposable()

    this.commands = new Commands()
    this.subscriptions.add(this.commands)

    this.commands.onShouldLint(() => {
      this.registryEditorsInit()
      const editorLinter = this.registryEditors.get(atom.workspace.getActiveTextEditor())
      if (editorLinter) {
        editorLinter.lint()
      }
    })
    this.commands.onShouldToggleActiveEditor(() => {
      const textEditor = atom.workspace.getActiveTextEditor()
      this.registryEditorsInit()
      const editor = this.registryEditors.get(textEditor)
      if (editor) {
        editor.dispose()
      } else if (textEditor) {
        this.registryEditors.createFromTextEditor(textEditor)
      }
    })
    this.commands.onShouldDebug(async () => {
      if (!Helpers) {
        Helpers = require('./helpers')
      }
      if (!manifest) {
        manifest = require('../package.json')
      }
      this.registryLintersInit()
      const linters = this.registryLinters.getLinters()
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
      const disabledLinters = atom.config.get('linter.disabledProviders')
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
      if (!ToggleView) {
        ToggleView = require('./toggle-view')
      }
      if (!arrayUnique) {
        arrayUnique = require('lodash.uniq')
      }
      this.registryLintersInit()
      const toggleView = new ToggleView(action,
        arrayUnique(this.registryLinters.getLinters().map(linter => linter.name)))
      toggleView.onDidDispose(() => {
        this.subscriptions.remove(toggleView)
      })
      toggleView.onDidDisable((name) => {
        const linter = this.registryLinters.getLinters().find(entry => entry.name === name)
        if (linter) {
          this.registryMessagesInit()
          this.registryMessages.deleteByLinter(linter)
        }
      })
      toggleView.show()
      this.subscriptions.add(toggleView)
    })

    const projectPathChangeCallbackID = window.requestIdleCallback(
      function projectPathChange() {
        this.idleCallbacks.delete(projectPathChangeCallbackID)
        // NOTE: Atom triggers this on boot so wait a while
        this.subscriptions.add(atom.project.onDidChangePaths(() => {
          this.commands.lint()
        }))
      }.bind(this))
    this.idleCallbacks.add(projectPathChangeCallbackID)

    const registryEditorsInitCallbackID = window.requestIdleCallback(
      function registryEditorsIdleInit() {
        this.idleCallbacks.delete(registryEditorsInitCallbackID)
        // This will be called on the fly if needed, but needs to run on it's
        // own at some point or linting on open or on change will never trigger
        this.registryEditorsInit()
      }.bind(this))
    this.idleCallbacks.add(registryEditorsInitCallbackID)
  }
  dispose() {
    this.idleCallbacks.forEach(callbackID => window.cancelIdleCallback(callbackID))
    this.idleCallbacks.clear()
    this.subscriptions.dispose()
  }

  registryEditorsInit() {
    if (this.registryEditors) {
      return
    }
    if (!EditorsRegistry) {
      EditorsRegistry = require('./editor-registry')
    }
    this.registryEditors = new EditorsRegistry()
    this.subscriptions.add(this.registryEditors)
    this.registryEditors.observe((editorLinter) => {
      editorLinter.onShouldLint((onChange) => {
        this.registryLintersInit()
        this.registryLinters.lint({ onChange, editor: editorLinter.getEditor() })
      })
      editorLinter.onDidDestroy(() => {
        this.registryMessagesInit()
        this.registryMessages.deleteByBuffer(editorLinter.getEditor().getBuffer())
      })
    })
    this.registryEditors.activate()
  }
  registryLintersInit() {
    if (this.registryLinters) {
      return
    }
    if (!LinterRegistry) {
      LinterRegistry = require('./linter-registry')
    }
    this.registryLinters = new LinterRegistry()
    this.subscriptions.add(this.registryLinters)
    this.registryLinters.onDidUpdateMessages(({ linter, messages, buffer }) => {
      this.registryMessagesInit()
      this.registryMessages.set({ linter, messages, buffer })
    })
    this.registryLinters.onDidBeginLinting(({ linter, filePath }) => {
      this.registryUIInit()
      this.registryUI.didBeginLinting(linter, filePath)
    })
    this.registryLinters.onDidFinishLinting(({ linter, filePath }) => {
      this.registryUIInit()
      this.registryUI.didFinishLinting(linter, filePath)
    })
  }
  registryIndieInit() {
    if (this.registryIndie) {
      return
    }
    if (!IndieRegistry) {
      IndieRegistry = require('./indie-registry')
    }
    this.registryIndie = new IndieRegistry()
    this.subscriptions.add(this.registryIndie)
    this.registryIndie.observe((indieLinter) => {
      indieLinter.onDidDestroy(() => {
        this.registryMessagesInit()
        this.registryMessages.deleteByLinter(indieLinter)
      })
    })
    this.registryIndie.onDidUpdate(({ linter, messages }) => {
      this.registryMessagesInit()
      this.registryMessages.set({ linter, messages, buffer: null })
    })
  }
  registryMessagesInit() {
    if (this.registryMessages) {
      return
    }
    if (!MessageRegistry) {
      MessageRegistry = require('./message-registry')
    }
    this.registryMessages = new MessageRegistry()
    this.subscriptions.add(this.registryMessages)
    this.registryMessages.onDidUpdateMessages((difference) => {
      this.registryUIInit()
      this.registryUI.render(difference)
    })
  }
  registryUIInit() {
    if (this.registryUI) {
      return
    }
    if (!UIRegistry) {
      UIRegistry = require('./ui-registry')
    }
    this.registryUI = new UIRegistry()
    this.subscriptions.add(this.registryUI)
  }

  // API methods for providing/consuming services
  // UI
  addUI(ui: UI) {
    this.registryUIInit()
    this.registryUI.add(ui)
    this.registryMessagesInit()
    const messages = this.registryMessages.messages
    if (messages.length) {
      ui.render({ added: messages, messages, removed: [] })
    }
  }
  deleteUI(ui: UI) {
    this.registryUIInit()
    this.registryUI.delete(ui)
  }
  // Standard Linter
  addLinter(linter: LinterProvider, legacy: boolean = false) {
    this.registryLintersInit()
    this.registryLinters.addLinter(linter, legacy)
  }
  deleteLinter(linter: LinterProvider) {
    this.registryLintersInit()
    this.registryLinters.deleteLinter(linter)
    this.registryMessagesInit()
    this.registryMessages.deleteByLinter(linter)
  }
  // Indie Linter
  addIndie(indie: Object) {
    this.registryIndieInit()
    return this.registryIndie.register(indie, 2)
  }
  addLegacyIndie(indie: Object) {
    this.registryIndieInit()
    return this.registryIndie.register(indie, 1)
  }
}

module.exports = Linter
