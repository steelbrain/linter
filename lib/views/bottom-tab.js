'use strict';

class BottomTab extends HTMLElement{

  initialize(Content, onClick) {
    this.innerHTML = Content
    this.classList.add('linter-tab')

    this.countSpan = document.createElement('span')
    this.countSpan.classList.add('count')
    this.countSpan.textContent = '0'

    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countSpan)

    this.addEventListener('click', onClick)
  }

  set active(value) {
    if (value) {
      this.classList.add('active')
    } else {
      this.classList.remove('active')
    }
    this._active = value
  }

  set count(value) {
    this._count = value
    this.countSpan.textContent = value
  }
}

module.exports = BottomTab = document.registerElement('linter-bottom-tab', {
  prototype: BottomTab.prototype
})
