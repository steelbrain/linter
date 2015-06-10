BottomTab = require './bottom-tab'

class BottomTabFile extends BottomTab
  initialize: (@linter)->
    BottomTab.prototype.initialize.call(this, "Current File") # document.registerElement destroys it prototype chain
  onClick: ->
    @linter.views.scope = 'file'
    @linter.views.bottomTabProject.active = false
    @active = true
module.exports = BottomTabFile = document.registerElement('linter-bottom-tab-file', {prototype: BottomTabFile.prototype})