BottomTab = require './bottom-tab'

class BottomTabProject extends BottomTab
  initialize: (linter)->
    BottomTab.prototype.initialize.call(this, "Current File", linter) ## document.registerElement destroy's it prototype chain
  onClick: ->

module.exports = BottomTabProject = document.registerElement('linter-bottom-tab-project', {prototype: BottomTabProject.prototype})