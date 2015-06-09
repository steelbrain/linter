module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean'
      default: true
    showErrorInline:
      type: 'boolean'
      default: true

  activate: ->
    @instance = new (require './linter-plus.coffee')
    atom.config.observe 'linter-plus.lintOnFly', (lintOnyFly) =>
      @instance.lintOnFly = lintOnyFly

    legacy = require('./legacy.coffee')
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implemention = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        linter = legacy(require "#{atomPackage.path}/lib/#{implemention}")
        @consumeLinter(linter)
      if atomPackage.metadata.providedServices?['linter-plus']?.versions['0.1.0']
        atom.notifications.addWarning("#{atomPackage.name} still provides
        `linter-plus` this has been depricated in favor of `linter`")

  consumeLinter: (linter) ->
    @instance.linters.push linter

  consumeLinterPlus: (linter) ->
    @instance.linters.push linter

  consumeStatusBar: (statusBar) ->
    @instance.bottom.initialize(statusBar)

  provideLinter: ->
    @Linter

  deactivate: ->
    @instance?.deactivate()
