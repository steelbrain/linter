BottomTab = require './bottom-tab'

class BottomTabProject extends BottomTab
  initialize: (linter)->
    BottomTab.prototype.initialize.call(this, "Current File", linter) ## document.registerElement destroys it prototype chain
  onClick: ->
    @linter.views.scope = 'project'
    @linter.views.bottomTabFile.active = false
    @active = true

module.exports = BottomTabProject = document.registerElement('linter-bottom-tab-project', {prototype: BottomTabProject.prototype})