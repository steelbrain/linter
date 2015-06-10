BottomTabFile = require './views/bottom-tab-file'
BottomTabProject = require './views/bottom-tab-project'

class LinterViews
  constructor: (@linter)->
    @bottomTabFile = new BottomTabFile()
    @bottomTabProject = new BottomTabProject()

    @bottomTabFile.initialize(@linter)
    @bottomTabProject.initialize(@linter)

    # Set default tab to File
    @scope = 'file'
    @bottomTabFile.active = true

  # This method is called when we get the status-bar service
  attachBottom: (statusBar)->
    statusBar.addLeftTile
      item: @bottomTabFile,
      priority: -1001
    statusBar.addLeftTile
      item: @bottomTabProject,
      priority: -1001

# this method is called on package deactivate
  deactivate: ->

module.exports = LinterViews