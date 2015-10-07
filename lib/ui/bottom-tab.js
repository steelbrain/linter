'use babel'

export default class BottomTab extends HTMLElement {
  createdCallback() {
    this.nameElement = document.createTextNode('')
    this.countElement = document.createElement('span')
    this.countElement.classList.add('count')

    this.appendChild(this.nameElement)
    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countElement)

    this.count = 0
  }

  set name(name) {
    this.nameElement.textContent = name
  }
  get name() {
    return this.nameElement.textContent
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
    el.name = name
    return el
  }
}

document.registerElement('linter-bottom-tab', {
  prototype: BottomTab.prototype
})
