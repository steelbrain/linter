BottomTab = require './bottom-tab'

class BottomTabFile extends BottomTab
  initialize: (linter)->
    BottomTab.prototype.initialize.call(this, "Current File", linter) # document.registerElement destroy's it prototype chain
  onClick: ->

module.exports = BottomTabFile = document.registerElement('linter-bottom-tab-file', {prototype: BottomTabFile.prototype})