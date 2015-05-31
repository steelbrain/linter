class PanelView extends HTMLElement
  initialize: (@Model, @Linter)->
    @Model.View = this
  createdCallback: ->
    this.id = 'linter-panel'
  render: (Messages)->
    Messages.forEach (Message)=>
      @appendChild @Linter.View.messageLine Message, @Model.Type is 'project'
module.exports = PanelView = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})
