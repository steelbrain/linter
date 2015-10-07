'use babel'

import {CompositeDisposable} from 'atom'

export default class BottomTab extends HTMLElement {
  createdCallback() {
    this.status = false
    this.subscriptions = new CompositeDisposable()

    this.nameElement = document.createTextNode('')
    this.countElement = document.createElement('span')
    this.countElement.classList.add('count')

    this.appendChild(this.nameElement)
    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countElement)

    this.count = 0
  }
  prepare(name) {
    this.nameElement.textContent = name
    this.subscriptions.add(atom.config.observe(`linter.showErrorTab${name}`, status => {
      if (status) {
        this.removeAttribute('hidden')
      } else {
        this.setAttribute('hidden', true)
      }
    }))
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
