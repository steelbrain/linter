'use babel'

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
    // TODO: Add Message here
    // TODO: Add link here
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
