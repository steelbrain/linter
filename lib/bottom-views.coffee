Views = {
  currentFile:(linter) ->
    root = document.createElement 'div'
    root.innerHTML = 'Current File'
    root.classList.add 'linter-tab'
    root.classList.add 'active'
    root.addEventListener 'click', ->
      linter.bottom.barProject.root.classList.remove 'active'
      root.classList.add 'active'
      linter.panel.type = 'file'
      linter.view.render()
    root.appendChild document.createTextNode ' '
    child = document.createElement 'span'
    child.classList.add 'badge-flexible'
    child.textContent = '0'
    root.appendChild child
    {root, child}
  wholeProject: (linter) ->
    root = document.createElement 'div'
    root.innerHTML = 'Project'
    root.classList.add 'linter-tab'
    root.addEventListener 'click', ->
      linter.bottom.barCurrent.root.classList.remove 'active'
      root.classList.add 'active'
      linter.panel.type = 'project'
      linter.view.render()
    root.appendChild document.createTextNode ' '
    child = document.createElement 'span'
    child.classList.add 'badge'
    child.classList.add 'badge-flexible'
    child.textContent = '0'
    root.appendChild child
    {root, child}
  status: ->
    root = document.createElement 'div'
    root.classList.add 'linter-success'
    root.classList.add 'inline-block'
    child = document.createElement 'span'
    child.classList.add 'icon'
    root.appendChild child
    return {root, child}
}
module.exports = Views
