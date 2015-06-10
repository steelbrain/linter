"use strict";
class BottomTab extends HTMLDivElement{
  constructor(Content, linter){
    this.linter = linter
    this._active = true
    this._count = 0

    this.innerHTML = Content
    this.classList.add('linter-tab')

    this.countSpan = document.createElement('span')
    this.countSpan.classList.add('badge')
    this.countSpan.classList.add('badge-flexible')
    this.countSpan.textContent = '0'

    this.appendChild(document.createTextNode(' '))
    this.appendChild(this.countSpan)

    this.addEventListener('click', this.onClick)
  }
  get active(){
    return this._active
  }
  set active(value){
    if(value){
      this.classList.add('active')
    } else {
      this.classList.remove('active')
    }
    this._active = value
  }
  get count(){
    return this._count
  }
  set count(value){
    this._count = value
    this.countSpan.textContent = value
  }
  onClick(){} // To be replaced by the extending classes
}

// module.exports = BottomTab = document.registerElement('linter-bottom-tab', {prototype: BottomTab.prototype})
module.exports = BottomTab