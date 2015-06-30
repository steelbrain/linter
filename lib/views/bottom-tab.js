'use strict';

class BottomTab extends HTMLElement{
  constructor(Content){
    this.innerHTML = Content
  }
  attachedCallback() {
    this.active = false
    this.visibility = false
    this.classList.add('linter-tab')

    this.countSpan = document.createElement('span')
    this.countSpan.classList.add('count')
    this.countSpan.textContent = '0'

    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countSpan)
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
