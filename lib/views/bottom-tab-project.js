"use strict";
let BottomTab = require('./bottom-tab')

class BottomTabProject extends BottomTab{
  initialize(linter){
    this.linter = linter
    super.initialize("Project")
  }
  onClick(){
    this.linter.views.scope = 'project'
    this.linter.views.bottomTabFile.active = false
    this.active = true
    this.linter.views.panel.render(this.linter.views.messages)
  }
}
module.exports = BottomTabProject = document.registerElement('linter-bottom-tab-project', {
  prototype: BottomTabProject.prototype
})