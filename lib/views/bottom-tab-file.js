"use strict";
let BottomTab = require('./bottom-tab')

class BottomTabFile extends BottomTab{
  initialize(linter){
    this.linter = linter
    super.initialize("Current File")
  }
  onClick(){
    this.linter.views.changeTab('file')
    this.linter.views.update()
  }
}
module.exports = BottomTabFile = document.registerElement('linter-bottom-tab-file', {
  prototype: BottomTabFile.prototype
})