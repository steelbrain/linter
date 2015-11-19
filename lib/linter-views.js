'use babel'

import {Emitter, CompositeDisposable} from 'atom'
import BottomPanel from './ui/bottom-panel'
import {Message} from './ui/message-element'
import Helpers from './helpers'
import {create as createBubble} from './ui/message-bubble'

export default class LinterViews {
  constructor() {
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()
    this.bottomPanel = new BottomPanel()
    this.bottomBar = null // To be added when status-bar service is consumed
    this.bubble = null
    this.bubbleRange = null

    this.subscriptions.add(this.bottomPanel)
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

    this._renderBubble = this.renderBubble
    this.subscriptions.add(atom.config.observe('linter.inlineTooltipInterval', bubbleInterval =>
      this.renderBubble = Helpers.debounce(this._renderBubble, bubbleInterval)
    ))
  }
  render({added, removed, messages}) {
    this.messages = messages
  }
  renderBubble(editorLinter) {
    if (!this.showBubble || !editorLinter.messages.size) {
      return
    }
    const point = editorLinter.editor.getCursorBufferPosition()
    if (this.bubbleRange && this.bubbleRange.containsPoint(point)) {
      return // The marker remains the same
    } else if (this.bubble) {
      this.bubble.destroy()
      this.bubble = null
    }
    for (let entry of editorLinter.markers) {
      const bubbleRange = entry[1].getBufferRange()
      if (bubbleRange.containsPoint(point)) {
        this.bubbleRange = bubbleRange
        this.bubble = editorLinter.editor.decorateMarker(entry[1], {
          type: 'overlay',
          item: createBubble(entry[0])
        })
        return
      }
    }
    this.bubbleRange = null
  }
  dispose() {
    // No need to notify editors of this, we're being disposed means the package is
    // being deactivated. They'll be disposed automatically by the registry.
    this.subscriptions.dispose()
    if (this.bottomBar) {
      this.bottomBar.destroy()
    }
    if (this.bubble) {
      this.bubble.destroy()
      this.bubbleRange = null
    }
  }
}
