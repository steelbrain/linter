class PanelView extends HTMLElement
  registerModel: (Model)->
    @Model = Model
    @Model.View = this
  createdCallback: ->
    this.id = 'linter-panel'
  render: (Messages)->
    this.innerHTML = Messages.length
module.exports = PanelView = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})
