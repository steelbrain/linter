'use strict';

class BottomTab extends HTMLElement{
  prepare(Name){
    this.Name = Name
    this.attached = false
    return this
  }
  attachedCallback() {
    this.active = false
    this.attached = true
    this.classList.add('linter-tab')

    this.countSpan = document.createElement('span')
    this.countSpan.classList.add('count')
    this.countSpan.textContent = '0'

    this.innerHTML = this.Name + ' '
    this.appendChild(this.countSpan)
  }
  detachedCallback(){
    this.attached = false
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
}

module.exports = BottomTab = document.registerElement('linter-bottom-tab', {
  prototype: BottomTab.prototype
})
