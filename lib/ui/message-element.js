'use babel'

class Message extends HTMLElement {
  initialize(message, scope) {
    this.message = message
    this.scope = scope
    return this
  }
  refresh(scope) {
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
    this.textContent = 'I am a message'
    // TODO: Add ribbon here
    // TODO: Add Message here
    // TODO: Add link here
  }
}

const MessageElement = document.registerElement('linter-message', {
  prototype: Message.prototype
})

export default function(message, scope) {
  return new MessageElement().initialize(message, scope)
}
