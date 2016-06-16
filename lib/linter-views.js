'use babel'

import {Emitter, CompositeDisposable, Range} from 'atom'
import BottomPanel from './ui/bottom-panel'
import BottomContainer from './ui/bottom-container'
import {Message} from './ui/message-element'
import Helpers from './helpers'
import {create as createBubble} from './ui/message-bubble'

export default class LinterViews {
  constructor(scope, editorRegistry) {
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()
    this.bottomPanel = new BottomPanel(scope)
    this.bottomContainer = BottomContainer.create(scope)
    this.editors = editorRegistry
    this.bottomBar = null // To be added when status-bar service is consumed
    this.bubble = null

    this.subscriptions.add(this.bottomPanel)
    this.subscriptions.add(this.bottomContainer)
    this.subscriptions.add(this.emitter)

    this.count = {
      Line: 0,
      File: 0,
      Project: 0
    }
    this.messages = []
    this.subscriptions.add(atom.config.observe('linter.showErrorInline', showBubble =>
      this.showBubble = showBubble
    ))
    this.subscriptions.add(atom.workspace.onDidChangeActivePaneItem(paneItem => {
      let isEditor = false
      this.editors.forEach(function(editorLinter) {
        isEditor = (editorLinter.active = editorLinter.editor === paneItem) || isEditor
      })
      this.updateCounts()
      this.bottomPanel.refresh()
      this.bottomContainer.visibility = isEditor
    }))
    this.subscriptions.add(this.bottomContainer.onDidChangeTab(scope => {
      this.emitter.emit('did-update-scope', scope)
      atom.config.set('linter.showErrorPanel', true)
      this.bottomPanel.refresh(scope)
    }))
    this.subscriptions.add(this.bottomContainer.onShouldTogglePanel(function() {
      atom.config.set('linter.showErrorPanel', !atom.config.get('linter.showErrorPanel'))
    }))

    this._renderBubble = this.renderBubble
    this.subscriptions.add(atom.config.observe('linter.inlineTooltipInterval', bubbleInterval =>
      this.renderBubble = Helpers.debounce(this._renderBubble, bubbleInterval)
    ))
  }
  render({added, removed, messages}) {
    this.messages = messages
    this.notifyEditorLinters({added, removed})
    this.bottomPanel.setMessages({added, removed})
    this.updateCounts()
  }
  updateCounts() {
    const activeEditorLinter = this.editors.ofActiveTextEditor()

    this.count.Project = this.messages.length
    this.count.File = activeEditorLinter ? activeEditorLinter.getMessages().size : 0
    this.count.Line = activeEditorLinter ? activeEditorLinter.countLineMessages : 0
    this.bottomContainer.setCount(this.count)
  }
  renderBubble(editorLinter) {
    if (!this.showBubble || !editorLinter.messages.size) {
      this.removeBubble()
      return
    }
    const point = editorLinter.editor.getCursorBufferPosition()
    if (this.bubble && editorLinter.messages.has(this.bubble.message) && this.bubble.range.containsPoint(point)) {
      return // The marker remains the same
    }
    this.removeBubble()
    for (let message of editorLinter.messages) {
      if (message.range && message.range.containsPoint(point)) {
        const range = Range.fromObject([point, point])
        const marker = editorLinter.editor.markBufferRange(range, {invalidate: 'inside'})
        this.bubble = {message, range, marker}
        marker.onDidDestroy(() => {
          this.bubble = null
        })
        editorLinter.editor.decorateMarker(marker, {
          type: 'overlay',
          item: createBubble(message)
        })
        break
      }
    }
  }
  removeBubble() {
    if (this.bubble) {
      this.bubble.marker.destroy()
      this.bubble = null
    }
  }
  notifyEditorLinters({added, removed}) {
    let editorLinter
    removed.forEach(message => {
      if (message.filePath && (editorLinter = this.editors.ofPath(message.filePath))) {
        editorLinter.deleteMessage(message)
      }
    })
    added.forEach(message => {
      if (message.filePath && (editorLinter = this.editors.ofPath(message.filePath))) {
        editorLinter.addMessage(message)
      }
    })
    editorLinter = this.editors.ofActiveTextEditor()
    if (editorLinter) {
      editorLinter.calculateLineMessages(null)
      this.renderBubble(editorLinter)
    } else {
      this.removeBubble()
    }
  }
  notifyEditorLinter(editorLinter) {
    const path = editorLinter.editor.getPath()
    if (!path) return
    this.messages.forEach(function(message) {
      if (message.filePath && message.filePath === path) {
        editorLinter.addMessage(message)
      }
    })
  }
  attachBottom(statusBar) {
    this.subscriptions.add(atom.config.observe('linter.statusIconPosition', position => {
      if (this.bottomBar) {
        this.bottomBar.destroy()
      }
      this.bottomBar = statusBar[`add${position}Tile`]({
        item: this.bottomContainer,
        priority: position === 'Left' ? -100 : 100
      })
    }))
  }

  onDidUpdateScope(callback) {
    return this.emitter.on('did-update-scope', callback)
  }
  dispose() {
    // No need to notify editors of this, we're being disposed means the package is
    // being deactivated. They'll be disposed automatically by the registry.
    this.subscriptions.dispose()
    if (this.bottomBar) {
      this.bottomBar.destroy()
    }
    this.removeBubble()
  }
}
