'use babel'

const NewLine = /\r?\n/

class Message extends HTMLElement {
  initialize(message, scope) {
    this.message = message
    this.scope = scope
    return this
  }
  updateVisibility(scope) {
    let status = true
    if (scope === 'Line')
      status = this.message.currentLine
    else if (scope === 'File')
      status = this.message.currentFile

    if (status)
      this.removeAttribute('hidden')
    else
      this.setAttribute('hidden', true)
    this.scope = scope
  }
  attachedCallback() {
    this.appendChild(Message.getRibbon(this.message))
    this.appendChild(Message.getMessage(this.message))
    // TODO: Add link here
  }
  static getMessage(message) {
    const el = document.createElement('span')
    el.className = 'linter-message-item'
    if (message.html && typeof message.html !== 'string') {
      el.appendChild(message.html.cloneNode(true))
    } else if (
      (message.html && message.html.match(NewLine)) ||
      (message.text && message.text.match(NewLine))
    ) {
      // TODO: Treat this as multi-line
    } else {
      if (message.html) {
        el.innerHTML = message.html
      } else if (message.text) {
        el.textContent = message.text
      }
    }
    return el
  }
  static getRibbon(message) {
    const el = document.createElement('span')
    el.className = `linter-message-item badge badge-flexible linter-highlight ${message.class}`
    el.textContent = message.type
    return el
  }
}

const MessageElement = document.registerElement('linter-message', {
  prototype: Message.prototype
})

export default function(message, scope) {
  return new MessageElement().initialize(message, scope)
}
