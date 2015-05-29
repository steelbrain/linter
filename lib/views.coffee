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
  status: ->
    Root = document.createElement 'div'
    Root.classList.add 'linter-success'
    Root.classList.add 'inline-block'
    Child = document.createElement 'span'
    Child.classList.add 'icon'
    Root.appendChild Child
    return {Root, Child}
}
module.exports = {Tiles}