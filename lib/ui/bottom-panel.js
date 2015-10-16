'use babel'

const Interact = require('interact.js')
const Clipboard = require('clipboard')
import {CompositeDisposable} from 'atom'
import {Message} from './message-element'

export default class BottomPanel {
  constructor(scope, editorRegistry) {
    this.subscriptions = new CompositeDisposable
    this.element = document.createElement('linter-panel') // TODO(steelbrain): Make this a `div`
    this.element.tabIndex = '-1'
    this.messagesElement = document.createElement('div')
    this.panel = atom.workspace.addBottomPanel({item: this.element, visible: false, priority: 500})
    this.visibility = false
    this.visibleMessages = 0
    this.alwaysTakeMinimumSpace = atom.config.get('linter.alwaysTakeMinimumSpace')
    this.errorPanelHeight = atom.config.get('linter.errorPanelHeight')
    this.configVisibility = atom.config.get('linter.showErrorPanel')
    this.scope = scope
    this.editorMessages = new Map()
    this.messages = new Map()

    // Keep messages contained to measure height.
    this.element.appendChild(this.messagesElement)

    this.subscriptions.add(atom.config.onDidChange('linter.alwaysTakeMinimumSpace', ({newValue}) => {
      this.alwaysTakeMinimumSpace = newValue
      this.updateHeight()
    }))

    this.subscriptions.add(atom.config.onDidChange('linter.errorPanelHeight', ({newValue}) => {
      this.errorPanelHeight = newValue
      this.updateHeight()
    }))

    this.subscriptions.add(atom.config.onDidChange('linter.showErrorPanel', ({newValue}) => {
      this.configVisibility = newValue
      this.updateVisibility()
    }))

    this.subscriptions.add(atom.workspace.observeActivePaneItem(paneItem => {
      this.paneVisibility = paneItem === atom.workspace.getActiveTextEditor()
      this.updateVisibility()
    }))
    this.subscriptions.add(editorRegistry.observe(editorLinter => {
      const container = document.createElement('div')
      this.messagesElement.appendChild(container)
      this.editorMessages.set(editorLinter, container)
      editorLinter.onDidDestroy(() => {
        container.remove()
        // TODO: Remove our messages? What about project-scoped ones?
        this.editorMessages.delete(editorLinter)
      })
      editorLinter.onDidMessageChange(({message, type}) => {
        if (type === 'add') {
          const messageElement = Message.fromMessage(message)
          this.messages.set(message, messageElement)
          container.appendChild(messageElement)
          if (messageElement.updateVisibility(this.scope).status) {
            this.visibleMessages++
          }
        } else {
          const messageElement = this.messages.get(message)
          this.messages.delete(message)
          messageElement.remove()
          if (messageElement.status) {
            this.visibleMessages--
          }
        }
      })
    }))

    Interact(this.element).resizable({edges: {top: true}})
      .on('resizemove', event => {
        event.target.style.height = `${event.rect.height}px`
      })
      .on('resizeend', event => {
        atom.config.set('linter.errorPanelHeight', event.target.clientHeight)
      })
    this.element.addEventListener('keydown', function(e) {
      if (e.which === 67 && e.ctrlKey) {
        Clipboard.writeText(getSelection().toString())
      }
    })
  }
  refresh(scope) {
    if (scope) {
      this.scope = scope
    } else scope = this.scope
    this.visibleMessages = 0

    for (let message of this.messages) {
      if (message[1].updateVisibility(scope).status) {
        this.visibleMessages++
      }
    }

    this.updateVisibility()
  }
  updateHeight() {
    let height = this.errorPanelHeight

    if (this.alwaysTakeMinimumSpace) {
      // Add `1px` for the top border.
      height = Math.min(this.messagesElement.clientHeight + 1, height)
    }

    this.element.style.height = `${height}px`
  }
  getVisibility() {
    return this.visibility
  }
  updateVisibility() {
    this.visibility = this.configVisibility && this.paneVisibility && this.visibleMessages > 0

    if (this.visibility) {
      this.panel.show()
      this.updateHeight()
    } else {
      this.panel.hide()
    }
  }
  dispose() {
    this.subscriptions.dispose()
    this.messages.clear()
    this.panel.destroy()
  }
}
