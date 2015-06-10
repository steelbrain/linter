BottomTab = require './bottom-tab'

class BottomTabFile extends BottomTab
  constructor: (linter)->
    super("Current File", linter)
  onClick: ->

module.exports = BottomTabFile = document.registerElement('linter-bottom-tab-file', {prototype: BottomTabFile.prototype})