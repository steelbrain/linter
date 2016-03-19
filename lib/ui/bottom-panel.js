'use babel'

const Interact = require('interact.js')
let Clipboard
try {
  Clipboard = require('electron').clipboard
} catch (_) {
  Clipboard = require('clipboard')
}
import {CompositeDisposable} from 'atom'
import {Message} from './message-element'

export default class BottomPanel {
  constructor(scope) {
    this.subscriptions = new CompositeDisposable

    this.visibility = false
    this.visibleMessages = 0
    this.alwaysTakeMinimumSpace = atom.config.get('linter.alwaysTakeMinimumSpace')
    this.errorPanelHeight = atom.config.get('linter.errorPanelHeight')
    this.configVisibility = atom.config.get('linter.showErrorPanel')
    this.scope = scope
    this.editorMessages = new Map()
    this.messages = new Map()

    const element = document.createElement('linter-panel') // TODO(steelbrain): Make this a `div`
    element.tabIndex = '-1'
    this.messagesElement = document.createElement('div')
    element.appendChild(this.messagesElement)
    this.panel = atom.workspace.addBottomPanel({item: element, visible: false, priority: 500})
    Interact(element).resizable({edges: {top: true}})
      .on('resizemove', event => {
        event.target.style.height = `${event.rect.height}px`
      })
      .on('resizeend', event => {
        atom.config.set('linter.errorPanelHeight', event.target.clientHeight)
      })
    element.addEventListener('keydown', function(e) {
      if (e.which === 67 && e.ctrlKey) {
        Clipboard.writeText(getSelection().toString())
      }
    })

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

    // Container for messages with no filePath
    const defaultContainer = document.createElement('div')
    this.editorMessages.set(null, defaultContainer)
    this.messagesElement.appendChild(defaultContainer)
    if (scope !== 'Project') {
      defaultContainer.setAttribute('hidden', true)
    }
  }
  setMessages({added, removed}) {
    if (removed.length) {
      this.removeMessages(removed)
    }
    if (added.length) {
      let activeFile = atom.workspace.getActiveTextEditor()
      activeFile = activeFile ? activeFile.getPath() : undefined
      added.forEach(message => {
        if (!this.editorMessages.has(message.filePath)) {
          const container = document.createElement('div')
          this.editorMessages.set(message.filePath, container)
          this.messagesElement.appendChild(container)
          if (!(this.scope === 'Project' || activeFile === message.filePath)) {
            container.setAttribute('hidden', true)
          }
        }
        const messageElement = Message.fromMessage(message)
        this.messages.set(message, messageElement)
        this.editorMessages.get(message.filePath).appendChild(messageElement)
        if (messageElement.updateVisibility(this.scope).visibility) {
          this.visibleMessages++
        }
      })
    }

    this.editorMessages.forEach((child, key) => {
      // Never delete the default container
      if (key !== null && !child.childNodes.length) {
        child.remove()
        this.editorMessages.delete(key)
      }
    })

    this.updateVisibility()
  }
  removeMessages(messages) {
    messages.forEach(message => {
      const messageElement = this.messages.get(message)
      this.messages.delete(message)
      messageElement.remove()
      if (messageElement.visibility) {
        this.visibleMessages--
      }
    })
  }
  refresh(scope) {
    if (scope) {
      this.scope = scope
    } else scope = this.scope
    this.visibleMessages = 0

    this.messages.forEach(messageElement => {
      if (messageElement.updateVisibility(scope).visibility && scope === 'Line') {
        this.visibleMessages++
      }
    })

    if (scope === 'File') {
      let activeFile = atom.workspace.getActiveTextEditor()
      activeFile = activeFile ? activeFile.getPath() : undefined
      this.editorMessages.forEach((messagesElement, filePath) => {
        if (filePath === activeFile) {
          messagesElement.removeAttribute('hidden')
          this.visibleMessages = messagesElement.childNodes.length
        } else messagesElement.setAttribute('hidden', true)
      })
    } else if (scope === 'Project') {
      this.visibleMessages = this.messages.size
      this.editorMessages.forEach(messageElement => {
        messageElement.removeAttribute('hidden')
      })
    }

    this.updateVisibility()
  }
  updateHeight() {
    let height = this.errorPanelHeight

    if (this.alwaysTakeMinimumSpace) {
      // Add `1px` for the top border.
      height = Math.min(this.messagesElement.clientHeight + 1, height)
    }

    this.messagesElement.parentNode.style.height = `${height}px`
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
    try {
      this.panel.destroy()
    } catch (err) {
      // Atom fails weirdly sometimes when doing this
    }
  }
}
