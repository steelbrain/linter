'use strict'

let Message = require('./message')

class BottomPanel extends HTMLElement{
  prepare(){
    // priority because of https://github.com/AtomLinter/Linter/issues/668
    this.panel = atom.workspace.addBottomPanel({item: this, visible: false, priority: 500})
    this.panelVisibility = true
    return this
  }
  destroy(){
    this.panel.destroy()
  }
  get panelVisibility(){
    return this._panelVisibility
  }
  set panelVisibility(value){
    this._panelVisibility = value
    if(value) this.panel.show()
    else this.panel.hide()
  }
  get visibility(){
    return this._visibility
  }
  set visibility(value){
    this._visibility = value
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
