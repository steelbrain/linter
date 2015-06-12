"use strict";
let BottomTab = require('./bottom-tab')

class BottomTabFile extends BottomTab{
  initialize(linter){
    this.linter = linter
    super.initialize("Current File")
  }
  onClick(){
    this.linter.views.scope = 'file'
    this.linter.views.bottomTabProject.active = false
    this.active = true
    this.linter.views.panel.update()
  }
}
module.exports = BottomTabFile = document.registerElement('linter-bottom-tab-file', {
  prototype: BottomTabFile.prototype
})