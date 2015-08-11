'use babel'

import {CompositeDisposable} from 'atom'
import Message from './message'

export class BottomPanel {
  constructor() {
    this.subscriptions = new CompositeDisposable
    this.element = document.createElement('linter-panel') // TODO: Make this a `div`
    this.panel = atom.workspace.addBottomPanel({item: this.element, visible: false, priority: 500})
    this.visibility = false
    this.length = 0
    this.messages = new WeakMap()

    this.subscriptions.add(atom.config.observe('linter.showErrorPanel', value => {
      this.configVisibility = value
    }))
    // TODO: Hide on non-text-editors
  }
  setMessages({added, removed}) {
    if (removed.length)
      this.removeMessages(removed)
    for (let message of added) {
      this.length ++
      const messageElement = Message.fromMessage(message)
      this.messages.set(message, messageElement)
      this.element.appendChild(messageElement)
    }
    this.setVisibility(this.length)
  }
  removeMessages(removed) {
    for (let message of removed) {
      this.length --
      this.element.removeChild(this.messages.get(message))
      this.messages.delete(message)
    }
  }
  getVisibility() {
    return this.visibility
  }
  setVisibility(value){
    if (value && this.configVisibility) {
      this.panel.show()
    } else {
      this.panel.hide()
    }
    this.visibility = value
  }
  dispose() {
    this.subscriptions.dispose()
    this.messages.clear()
    this.panel.destroy()
  }
}
