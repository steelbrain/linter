'use babel'

class Message extends HTMLElement {
  initialize(message) {
    this.message = message
  }
  refresh(scope) {
    let status = true
    if (scope === 'Line')
      status = this.message.currentLine
    else if (scope === 'File')
      status = this.message.currentFile

    if (status)
      this.setAttribute('hidden', true)
    else
      this.removeAttribute('hidden')
  }
  attachedCallback() {

  }
}

const MessageElement = document.registerElement('linter-message', {
  prototype: Message.prototype
})

export default function(message) {
  // TODO: Construct and return a message element here
}
