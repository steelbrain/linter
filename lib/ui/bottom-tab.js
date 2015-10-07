'use babel'

import {CompositeDisposable, Emitter} from 'atom'

export default class BottomTab extends HTMLElement {
  createdCallback() {
    this.subscriptions = new CompositeDisposable()
    this.emitter = new Emitter()

    this.nameElement = document.createTextNode('')
    this.countElement = document.createElement('span')
    this.countElement.classList.add('count')

    this.appendChild(this.nameElement)
    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countElement)

    this.count = 0

    this.subscriptions.add(this.emitter)
    this.addEventListener('click', function() {
      if (this.active) {
        this.emitter.emit('should-toggle-panel')
      } else {
        this.emitter.emit('did-change-tab', this.name)
      }
    })
  }
  prepare(name) {
    this.name = name
    this.nameElement.textContent = name
    this.subscriptions.add(atom.config.observe(`linter.showErrorTab${name}`, status => {
      if (status) {
        this.removeAttribute('hidden')
      } else {
        this.setAttribute('hidden', true)
      }
    }))
  }
  onDidChangeTab(callback) {
    return this.emitter.on('did-change-tab', callback)
  }
  onShouldTogglePanel(callback) {
    return this.emitter.on('should-toggle-panel', callback)
  }
  dispose() {
    this.subscriptions.dispose()
  }

  set count(count) {
    this._count = count
    this.countElement.textContent = count
  }
  get count() {
    return this._count
  }

  set active(value) {
    this._active = value
    if (value) {
      this.classList.add('active')
    } else {
      this.classList.remove('active')
    }
  }
  get active() {
    return this._active
  }

  static create(name) {
    const el = document.createElement('linter-bottom-tab')
    el.prepare(name)
    return el
  }
}

document.registerElement('linter-bottom-tab', {
  prototype: BottomTab.prototype
})
