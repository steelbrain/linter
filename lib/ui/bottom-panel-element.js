'use strict'

let Message = require('./message')

class BottomPanel extends HTMLElement{

  updateMessages(messages, isProject) {
    this.clear()
    if (!messages.length) {
      return
    }
    messages.forEach(function(message) {
      this.appendChild(Message.fromMessage(message, {addPath: isProject, cloneNode: true}))
    }.bind(this))
  }

  clear() {
    while (this.firstChild) {
      this.removeChild(this.firstChild)
    }
  }

}

module.exports = document.registerElement('linter-panel', {prototype: BottomPanel.prototype})
