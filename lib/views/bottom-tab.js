'use strict';

class BottomTab extends HTMLElement{

  initialize(title, onClick) {
    this._active = false
    this._visibility = true
    this.title = title
    this.classList.add('linter-tab')

    this.textContent = '0'

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
    this.textContent = value
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
  set title(value) {
    this._title = value
    this.setAttribute('title', value)
  }
  get title() {
    return this._title
  }
}

module.exports = BottomTab = document.registerElement('linter-bottom-tab', {
  prototype: BottomTab.prototype
})
