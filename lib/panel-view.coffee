class PanelView extends HTMLElement
  initialize: (@Model, @Linter)->
    @Model.View = this
  createdCallback: ->
    this.id = 'linter-panel'
  render: (Messages)->
    @innerHTML = ''
    Messages.forEach (Message)=>
      return if @Model.Type is 'file' and not Message.CurrentFile
      @appendChild @Linter.View.messageLine Message, @Model.Type is 'project'
module.exports = PanelView = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})
