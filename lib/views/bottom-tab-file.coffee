BottomTab = require './bottom-tab'

class BottomTabFile extends BottomTab
  onClick: ->

module.exports = BottomTabFile = document.registerElement('linter-bottom-tab-file', {prototype: BottomTabFile.prototype})