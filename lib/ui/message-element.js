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

    if (this.message.filePath) {
      this.appendChild(Message.getLink(this.message))
    }
  }
  static getLink(message) {
    const el = document.createElement('a')
    let displayFile = message.filePath

    el.className = 'linter-message-item'

    for (let path of atom.project.getPaths())
      if (displayFile.indexOf(path) === 0) {
        displayFile = displayFile.substr(path.length + 1) // Path + Path Separator
        break
      }

    if (message.range) {
      el.textContent = `at line ${message.range.start.row + 1} col ${message.range.start.column + 1}`
    }
    // TODO: Implement filePath in message
    return el
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
      return Message.getMultiLineMessage(message.html || message.text)
    } else {
      if (message.html) {
        el.innerHTML = message.html
      } else if (message.text) {
        el.textContent = message.text
      }
    }
    return el
  }
  static getMultiLineMessage(message) {
    const container = document.createElement('linter-multiline-message')
    for (let line of message.split(NewLine)) {
      if (!line) continue
      const el = document.createElement('linter-message-line')
      el.textContent = line
      container.appendChild(el)
    }
    return container
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
