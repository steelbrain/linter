{View} = require 'space-pen'

class StatusTile extends View
  @content: (numErrors) ->
    if numErrors
      @div class: 'linter-error inline-block', =>
        @span class: 'icon icon-x', =>
          @text if numErrors is 1 then " #{numErrors} error" else " #{numErrors} errors"
    else
      @div class: 'linter-success inline-block', =>
        @span class: 'icon icon-check', =>
          @text ' No errors'
Tiles = {
  currentFile:(View) ->
    Root = document.createElement 'div'
    Root.innerHTML = 'Current File'
    Root.classList.add 'linter-tab'
    Root.classList.add 'active'
    Root.addEventListener 'click', ->
      View.BarProject.classList.remove 'active'
      Root.classList.add 'active'
      View.update()
    Root
  wholeProject: (View)->
    Root = document.createElement 'div'
    Root.innerHTML = 'Project'
    Root.classList.add 'linter-tab'
    Root.addEventListener 'click', ->
      View.BarCurrent.classList.remove 'active'
      Root.classList.add 'active'
      View.update()
    Root
}
module.exports = {StatusTile, Tiles}