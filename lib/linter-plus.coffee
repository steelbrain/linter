

module.exports =
  Instance: null
  activate:->
    @Instance = new (require './plus.coffee')
  consumeLinter:(Linter)->
    @Instance.Linters.push Linter
  deactivate:->
    @Instance?.deactivate()
