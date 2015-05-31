Views = require './bottom-views'

class Bottom
  constructor: (@Linter)->
    @BarCurrent = null
    @BarProject = null
    @BarStatus = null
  initialize: (StatusBar)->
    @BarCurrent = Views.currentFile(@Linter)
    @BarProject = Views.wholeProject(@Linter)
    @BarStatus = Views.status()
    @BarStatus.Child.classList.add 'icon-check'
    @BarStatus.Child.textContent = 'No Errors'
    StatusBar.addLeftTile
      item: @BarCurrent.Root,
      priority: -1001
    StatusBar.addLeftTile
      item: @BarProject.Root,
      priority: -1000
    StatusBar.addLeftTile
      item: @BarStatus.Root
      priority: -999
  update: (Messages)->
    CountTotal = Messages.length
    CountFile = Messages.filter( (Message) -> Message.CurrentFile).length
    @BarCurrent.Child.textContent = CountFile.toString()
    @BarProject.Child.textContent = CountTotal.toString()
    if CountTotal
      @BarStatus.Root.classList.remove 'linter-success'
      @BarStatus.Root.classList.add 'linter-error'
      @BarStatus.Child.classList.remove 'icon-check'
      @BarStatus.Child.classList.add 'icon-x'
      @BarStatus.Child.textContent = if CountTotal is 1 then '1 Error' else CountTotal + ' Errors'
    else
      @BarStatus.Root.classList.remove 'linter-error'
      @BarStatus.Root.classList.add 'linter-success'
      @BarStatus.Child.classList.remove 'icon-x'
      @BarStatus.Child.classList.add 'icon-check'
      @BarStatus.Child.textContent = 'No Errors'
  remove: ->
    # Not removing on purpose

module.exports = Bottom