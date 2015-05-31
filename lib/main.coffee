module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean'
      default: true

  activate: ->
    @instance = new (require './linter-plus.coffee')
    atom.config.observe 'linter-plus.lintOnFly', (lintOnyFly) =>
      @instance.lintOnFly = lintOnyFly

  consumeLinter: (linter) ->
    @instance.linters.push linter

  consumeStatusBar: (statusBar) ->
    @instance.bottom.initialize(statusBar)

  provideLinter: ->
    @Linter

  deactivate: ->
    @instance?.deactivate()
