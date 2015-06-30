'use strict'

class BottomPanel extends HTMLElement{
  set visibility(value){
    if(value){
      this.removeAttribute('hidden')
    } else {
      this.setAttribute('hidden', true)
    }
  }
  clear(){
    while(this.firstChild){
      this.removeChild(this.firstChild)
    }
  }
}

module.exports = document.registerElement('linter-panel', {prototype: BottomPanel.prototype})
