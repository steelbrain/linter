class Panel
  constructor: (@Linter)->

  registerView: (View)->
    @View = View
    @View.Model = this
module.exports = Panel