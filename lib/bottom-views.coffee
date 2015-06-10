Views = {
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
