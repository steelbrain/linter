'use babel'

const NewLine = /\r?\n/

export class Message extends HTMLElement {
  initialize(message, includeLink = true) {
    this.message = message
    this.includeLink = includeLink
    return this
  }
  updateVisibility(scope) {
    let status = true
    if (scope === 'Line')
      status = this.message.currentLine
    else if (scope === 'File')
      status = this.message.currentFile

    if (this.children.length && this.message.filePath)
      if (scope === 'Project')
        this.querySelector('.linter-message-link span').removeAttribute('hidden')
      else this.querySelector('.linter-message-link span').setAttribute('hidden', true)

    if (status)
      this.removeAttribute('hidden')
    else
      this.setAttribute('hidden', true)
  }
  attachedCallback() {
    if (atom.config.get('linter.showProviderName') && this.message.linter) {
      this.appendChild(Message.getName(this.message))
    }
    this.appendChild(Message.getRibbon(this.message))
    this.appendChild(Message.getMessage(this.message, this.includeLink))
  }
  static getLink(message) {
    const el = document.createElement('a')
    const pathEl = document.createElement('span')
    let displayFile = message.filePath

    el.className = 'linter-message-link'

    for (let path of atom.project.getPaths())
      if (displayFile.indexOf(path) === 0) {
        displayFile = displayFile.substr(path.length + 1) // Path + Path Separator
        break
      }

    if (message.range) {
      el.textContent = `at line ${message.range.start.row + 1} col ${message.range.start.column + 1}`
    }
    pathEl.textContent = ' in ' + displayFile
    el.appendChild(pathEl)
    el.addEventListener('click', function() {
      atom.workspace.open(message.filePath).then(function() {
        if (message.range) {
          atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)
        }
      })
    })
    return el
  }
  static getMessage(message, includeLink) {
    const el = document.createElement('span')
    const messageEl = document.createElement('span')

    el.className = 'linter-message-item'

    // Render link inside message content for float and auto flow text around.
    if (includeLink && message.filePath) {
      el.appendChild(Message.getLink(message))
    }

    el.appendChild(messageEl)

    if (message.html && typeof message.html !== 'string') {
      messageEl.appendChild(message.html.cloneNode(true))
    } else if (
      message.multiline ||
      (message.html && message.html.match(NewLine)) ||
      (message.text && message.text.match(NewLine))
    ) {
      return Message.getMultiLineMessage(message.html || message.text)
    } else {
      if (message.html) {
        messageEl.innerHTML = message.html
      } else if (message.text) {
        messageEl.textContent = message.text
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
  static getName(message) {
    const el = document.createElement('span')
    el.className = `linter-message-item badge badge-flexible linter-highlight ${message.class}`
    el.textContent = message.linter
    return el
  }
  static getRibbon(message) {
    const el = document.createElement('span')
    el.className = `linter-message-item badge badge-flexible linter-highlight ${message.class}`
    el.textContent = message.type
    return el
  }
  static fromMessage(message, includeLink) {
    return new MessageElement().initialize(message, includeLink)
  }
}

export const MessageElement = document.registerElement('linter-message', {
  prototype: Message.prototype
})
