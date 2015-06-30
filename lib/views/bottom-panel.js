'use strict'

class BottomPanel extends HTMLElement{
  set visibility(value){
    if(value){
      this.removeAttribute('hidden')
    } else {
      this.setAttribute('hidden', true)
    }
  }
}

module.exports = document.registerElement('linter-panel', {prototype: BottomPanel.prototype})
