'use strict'

let Message = require('./message')

class BottomPanel extends HTMLElement{
  prepare(){
    this.panel = atom.workspace.addBottomPanel({item: this, visible: true})
    return this
  }
  destroy(){
    this.panel.destroy()
  }
  set panelVisibility(value){
    if(value) this.panel.show()
    else this.panel.hide()
  }
  set visibility(value){
    if(value){
      this.removeAttribute('hidden')
    } else {
      this.setAttribute('hidden', true)
    }
  }
  updateMessages(messages, isProject){
    this.clear()
    if(!messages.length){
      return this.visibility = false
    }
    this.visibility = true
    messages.forEach(function(message){
      this.appendChild(Message.fromMessage(message, {addPath: isProject, cloneNode: true}))
    }.bind(this))
  }
  clear(){
    while(this.firstChild){
      this.removeChild(this.firstChild)
    }
  }
}

module.exports = document.registerElement('linter-panel', {prototype: BottomPanel.prototype})
