"use strict";
let BottomTab = require('./bottom-tab')

class BottomTabProject extends BottomTab{
  initialize(linter){
    this.linter = linter
    super.initialize("Project")
  }
  onClick(){
    this.linter.views.changeTab('project')
    this.linter.views.update()
  }
}
module.exports = BottomTabProject = document.registerElement('linter-bottom-tab-project', {
  prototype: BottomTabProject.prototype
})