'use babel'

const Interact = require('interact.js')
import {CompositeDisposable} from 'atom'
import {Message} from './message-element'

export default class BottomPanel {
  constructor() {
    this.subscriptions = new CompositeDisposable

    this.visibility = false
    this.alwaysTakeMinimumSpace = atom.config.get('linter.alwaysTakeMinimumSpace')
    this.errorPanelHeight = atom.config.get('linter.errorPanelHeight')

    const element = document.createElement('linter-panel') // TODO(steelbrain): Make this a `div`
    element.tabIndex = '-1'
    this.messagesElement = document.createElement('div')
    element.appendChild(this.messagesElement)
    Interact(element).resizable({edges: {top: true}})
      .on('resizemove', event => {
        event.target.style.height = `${event.rect.height}px`
      })
      .on('resizeend', event => {
        atom.config.set('linter.errorPanelHeight', event.target.clientHeight)
      })

    this.subscriptions.add(atom.config.onDidChange('linter.alwaysTakeMinimumSpace', ({newValue}) => {
      this.alwaysTakeMinimumSpace = newValue
      this.updateHeight()
    }))

    this.subscriptions.add(atom.config.onDidChange('linter.errorPanelHeight', ({newValue}) => {
      this.errorPanelHeight = newValue
      this.updateHeight()
    }))

  }
  setMessages({added, removed}) {
    this.updateVisibility()
  }
  removeMessages(messages) {}
  refresh(scope) {}
  updateHeight() {
    let height = this.errorPanelHeight

    if (this.alwaysTakeMinimumSpace) {
      // Add `1px` for the top border.
      height = Math.min(this.messagesElement.clientHeight + 1, height)
    }

    this.messagesElement.parentNode.style.height = `${height}px`
  }
  getVisibility() {}
  updateVisibility() {}
  dispose() {
    this.subscriptions.dispose()
  }
}
