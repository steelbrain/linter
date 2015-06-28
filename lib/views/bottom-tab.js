'use strict';

class BottomTab extends HTMLElement{

  initialize(Content, onClick) {
    this._active = false
    this._visibility = true
    this.innerHTML = Content
    this.classList.add('linter-tab')

    this.countSpan = document.createElement('span')
    this.countSpan.classList.add('count')
    this.countSpan.textContent = '0'

    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countSpan)

    this.addEventListener('click', onClick)
  }
  get active() {
    return this._active
  }
  set active(value) {
    this._active = value
    if (value) {
      this.classList.add('active')
    } else {
      this.classList.remove('active')
    }
  }
  set count(value) {
    this.countSpan.textContent = value
  }
  set visibility(value){
    this._visibility = value
    if(value){
      this.removeAttribute('hidden')
    } else {
      this.setAttribute('hidden', true)
    }
  }
  get visibility(){
    return this._visibility
  }
}

module.exports = BottomTab = document.registerElement('linter-bottom-tab', {
  prototype: BottomTab.prototype
})
