BottomTab = require './bottom-tab'

class BottomTabProject extends BottomTab
  constructor: (linter)->
    super("Project", linter)
  onClick: ->

module.exports = BottomTabProject = document.registerElement('linter-bottom-tab-project', {prototype: BottomTabProject.prototype})