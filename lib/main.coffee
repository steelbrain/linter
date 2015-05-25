

module.exports =
  Instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean',
      default: true
  activate:->
    @Instance = new (require './linter.coffee')
    atom.config.observe 'linter-plus.lintOnFly', (lintOnyFly) =>
      @Instance.LintOnFly = lintOnyFly
  consumeLinter:(Linter)->
    @Instance.Linters.push Linter
  deactivate:->
    @Instance?.deactivate()
