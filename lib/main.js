'use babel'

/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import type { TextEditor } from 'atom'
import type { Linter$UI, Linter$State, Linter$Linter } from './types'
import type EditorLinter from './editor-linter'
import Commands from './commands'
import UIRegistry from './ui-registry'
import IndieRegistry from './indie-registry'
import LinterRegistry from './linter-registry'
import MessageRegistry from './message-registry'
import EditorsRegistry from './editor-registry'

class Linter {
  state: Linter$State;
  commands: Commands;
  registryUI: UIRegistry;
  registryIndie: IndieRegistry;
  registryEditors: EditorsRegistry;
  registryLinters: LinterRegistry;
  registryMessages: MessageRegistry;

  subscriptions: CompositeDisposable;

  constructor(state: Linter$State) {
    this.state = state
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

    this.registryIndie.observe(indieLinter => {
      indieLinter.onDidDestroy(() => {
        this.registryMessages.deleteByLinter(indieLinter)
      })
    })
    this.registryIndie.onDidUpdateMessages(({linter, messages}) => {
      this.registryMessages.set({linter, messages, buffer: null})
    })
    this.registryLinters.onDidUpdateMessages(({linter, messages, buffer}) => {
      this.registryMessages.set({linter, messages, buffer})
    })
    this.registryLinters.onDidBeginLinting(({linter, filePath}) => {
      this.registryUI.didBeginLinting({linter, filePath})
    })
    this.registryLinters.onDidFinishLinting(({linter, filePath}) => {
      this.registryUI.didFinishLinting({linter, filePath})
    })
    this.registryMessages.onDidUpdateMessages(difference => {
      this.registryUI.didCalculateMessages(difference)
    })

    this.subscriptions.add(atom.workspace.observeTextEditors(textEditor => {
      this.createEditorLinter(textEditor)
    }))
    this.commands.onShouldLint(() => {
      const editor = this.registryEditors.ofActiveTextEditor()
      if (editor) {
        editor.lint()
      }
    })
    this.commands.onShouldToggleActiveEditor(() => {
      const textEditor = atom.workspace.getActiveTextEditor()
      const editor = this.registryEditors.ofTextEditor(textEditor)
      if (editor) {
        editor.dispose()
      } else if (textEditor) {
        this.createEditorLinter(textEditor)
      }
    })

    setImmediate(() => {
      this.subscriptions.add(atom.project.onDidChangePaths(() => {
        this.commands.lint()
      }))
    })
  }
  createEditorLinter(textEditor: TextEditor): EditorLinter {
    const editor = this.registryEditors.create(textEditor)
    editor.onShouldLint(onChange => {
      this.registryLinters.lint({onChange, editor: textEditor})
    })
    editor.onDidDestroy(() => {
      this.registryMessages.deleteByBuffer(textEditor.getBuffer())
    })
  }
  dispose() {
    this.subscriptions.dispose()
  }

  // API methods for providing/consuming services
  addUI(ui: Linter$UI) {
    this.registryUI.add(ui)
  }
  deleteUI(ui: Linter$UI) {
    this.registryUI.delete(ui)
  }
  addLinter(linter: Linter$Linter) {
    this.registryLinters.addLinter(linter)
  }
  deleteLinter(linter: Linter$Linter) {
    this.registryLinters.deleteLinter(linter)
    this.registryMessages.deleteByLinter(linter)
  }
}

module.exports = Linter
