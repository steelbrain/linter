Message = require './message'

class PanelView extends HTMLElement
  attachedCallback:(@linter) ->
    @id = 'linter-panel'

module.exports = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})