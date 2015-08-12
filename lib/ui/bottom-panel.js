'use babel'

import {CompositeDisposable} from 'atom'
import Message from './message-element'

export class BottomPanel {
  constructor(scope) {
    this.subscriptions = new CompositeDisposable
    this.element = document.createElement('linter-panel') // TODO: Make this a `div`
    this.panel = atom.workspace.addBottomPanel({item: this.element, visible: false, priority: 500})
    this.visibility = false
    this.scope = scope
    this.messages = new Map()

    this.subscriptions.add(atom.config.observe('linter.showErrorPanel', value => {
      this.configVisibility = value
      this.setVisibility(true)
    }))
    this.subscriptions.add(atom.workspace.observeActivePaneItem(paneItem => {
      this.paneVisibility = paneItem === atom.workspace.getActiveTextEditor()
      this.setVisibility(true)
    }))
  }
  refresh(scope) {
    this.scope = scope
    for (let message of this.messages) {
      message[1].updateVisibility(scope)
    }
  }
  setMessages({added, removed}) {
    if (removed.length)
      this.removeMessages(removed)
    for (let message of added) {
      const messageElement = Message(message, this.scope)
      this.messages.set(message, messageElement)
      this.element.appendChild(messageElement)
    }
  }
  removeMessages(removed) {
    for (let message of removed) {
      if (this.messages.has(message)) {
        this.element.removeChild(this.messages.get(message))
        this.messages.delete(message)
      }
    }
  }
  getVisibility() {
    return this.visibility
  }
  setVisibility(value){
    if (value && this.configVisibility && this.paneVisibility) {
      this.panel.show()
    } else {
      this.panel.hide()
    }
    this.visibility = value && this.configVisibility && this.paneVisibility
  }
  dispose() {
    this.subscriptions.dispose()
    this.messages.clear()
    this.panel.destroy()
  }
}
