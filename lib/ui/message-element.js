'use babel'

const NewLine = /\r?\n/

export class Message extends HTMLElement {
  initialize(message, includeLink = true) {
    this.message = message
    this.includeLink = includeLink
    this.status = false
    return this
  }
  updateVisibility(scope) {
    let status = true
    if (scope === 'Line')
      status = this.message.currentLine
    else if (scope === 'File')
      status = this.message.currentFile

    if (this.children.length && this.message.filePath) {
      const link = this.querySelector('.linter-message-link')
      if (link) {
        if (scope === 'Project') {
          link.querySelector('span').removeAttribute('hidden')
        } else {
          link.querySelector('span').setAttribute('hidden', true)
        }
      }
    }

    this.status = status

    if (status) {
      this.removeAttribute('hidden')
    } else this.setAttribute('hidden', true)

    return this
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
    if (message.multiline || NewLine.test(message.text)) {
      return Message.getMultiLineMessage(message, includeLink)
    }

    const el = document.createElement('span')
    const messageEl = document.createElement('linter-message-line')

    el.className = 'linter-message-item'

    el.appendChild(messageEl)

    if (includeLink && message.filePath) {
      el.appendChild(Message.getLink(message))
    }

    if (message.html && typeof message.html !== 'string') {
      messageEl.appendChild(message.html.cloneNode(true))
    } else if (message.html) {
      messageEl.innerHTML = message.html
    } else if (message.text) {
      messageEl.textContent = message.text
    }

    return el
  }
  static getMultiLineMessage(message, includeLink) {
    const container = document.createElement('span')
    const messageEl = document.createElement('linter-multiline-message')

    container.className = 'linter-message-item'
    messageEl.setAttribute('title', message.text)

    message.text.split(NewLine).forEach(function(line, index) {
      if (!line) return

      const el = document.createElement('linter-message-line')
      el.textContent = line
      messageEl.appendChild(el)

      // Render the link in the "title" line.
      if (index === 0 && includeLink && message.filePath) {
        messageEl.appendChild(Message.getLink(message))
      }
    })

    container.appendChild(messageEl)

    messageEl.addEventListener('click', function(e) {
      // Avoid opening the message contents when we click the link.
      var link = e.target.tagName === 'A' ? e.target : e.target.parentNode

      if (!link.classList.contains('linter-message-link')) {
        messageEl.classList.toggle('expanded')
      }
    })

    return container
  }
  static getName(message) {
    const el = document.createElement('span')
    el.className = 'linter-message-item badge badge-flexible linter-highlight'
    el.textContent = message.linter
    return el
  }
  static getRibbon(message) {
    const el = document.createElement('span')
    el.className = 'linter-message-item badge badge-flexible linter-highlight'
    el.className += ` ${message.class}`
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
