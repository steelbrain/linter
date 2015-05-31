Views = require './bottom-views'

class Bottom
  constructor: (@linter) ->
    @barCurrent = null
    @barProject = null
    @barStatus = null

  initialize: (statusBar) ->
    @barCurrent = Views.currentFile(@linter)
    @barProject = Views.wholeProject(@linter)
    @barStatus = Views.status()
    @barStatus.child.classList.add 'icon-check'
    @barStatus.child.textContent = 'No Errors'
    statusBar.addLeftTile
      item: @barCurrent.root,
      priority: -1001
    statusBar.addLeftTile
      item: @barProject.root,
      priority: -1000
    statusBar.addLeftTile
      item: @barStatus.root
      priority: -999

  update: (messages) ->
    countTotal = messages.length
    countFile = messages.filter((message) -> message.currentFile).length
    @barCurrent.child.textContent = countFile.toString()
    @barProject.child.textContent = countTotal.toString()
    if countTotal
      @barStatus.root.classList.remove 'linter-success'
      @barStatus.root.classList.add 'linter-error'
      @barStatus.child.classList.remove 'icon-check'
      @barStatus.child.classList.add 'icon-x'
      @barStatus.child.textContent = if countTotal is 1 then '1 Error' else countTotal + ' Errors'
    else
      @barStatus.root.classList.remove 'linter-error'
      @barStatus.root.classList.add 'linter-success'
      @barStatus.child.classList.remove 'icon-x'
      @barStatus.child.classList.add 'icon-check'
      @barStatus.child.textContent = 'No Errors'

  remove: ->
    # Not removing on purpose

module.exports = Bottom
