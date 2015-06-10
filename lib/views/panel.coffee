class PanelView extends HTMLElement
  initialize: (@model, @linter) ->
    @model.view = this

  createdCallback: ->
    this.id = 'linter-panel'

  render: (messages) ->
    @innerHTML = ''
    messages.forEach (message) =>
      return if @model.type is 'file' and not message.currentFile
      @appendChild @linter.view.messageLine message, @model.type is 'project'

module.exports = PanelView = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})
