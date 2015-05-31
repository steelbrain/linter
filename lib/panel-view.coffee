class PanelView extends HTMLElement
  constructor: ->
  registerModel: (Model)->
    @Model = Model
    @Model.View = this
  createdCallback: ->
    this.id = 'linter-panel'
  render: (Messages)->

module.exports = PanelView