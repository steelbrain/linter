class PanelView extends HTMLElement
  register: (Model)->
    @Model = Model
    @Model.View = this

module.exports = PanelView