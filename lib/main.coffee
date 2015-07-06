{Disposable} = require('atom')
module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean'
      default: true
    showErrorPanel:
      title: 'Show Error Panel at the bottom'
      type: 'boolean'
      default: true
    showErrorTabLine:
      title: 'Show Line tab in Bottom Panel'
      type: 'boolean'
      default: false
    showErrorTabFile:
      title: 'Show File tab in Bottom Panel'
      type: 'boolean'
      default: true
    showErrorTabProject:
      title: 'Show Project tab in Bottom Panel'
      type: 'boolean'
      default: true
    showErrorInline:
      title: 'Show Inline Tooltips'
      descriptions: 'Show inline tooltips for errors'
      type: 'boolean'
      default: true
    underlineIssues:
      title: 'Underline Issues'
      type: 'boolean'
      default: true
    statusIconPosition:
      title: 'Position of Status Icon on Bottom Bar'
      description: 'Requires a reload/restart to update'
      enum: ['Left', 'Right']
      type: 'string'
      default: 'Left'
    ignoredMessageTypes:
      title: "Ignored message Types"
      type: 'array'
      default: []
      items:
        type: 'string'

  activate: (state) ->
    LinterPlus = require('./linter-plus.coffee')
    @instance = new LinterPlus state

    legacy = require('./legacy.coffee')
    {deprecate} = require('grim')
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implementation = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        deprecate('AtomLinter v0.X.Y API has been deprecated.
          Please refer to the Linter docs to update and the latest API:
          https://github.com/AtomLinter/Linter/wiki/Migrating-to-the-new-API', {
          packageName: atomPackage.name
        })
        try
          linter = legacy(require("#{atomPackage.path}/lib/#{implementation}"))
          @consumeLinter(linter)
        catch error
          atom.notifications.addError "
            Failed to activate '#{atomPackage.metadata['name']}' package",
            {detail: error.message + "\n" + error.stack, dismissable: true}

  serialize: ->
    @instance.serialize()

  consumeLinter: (linters) ->
    unless linters instanceof Array
      linters = [ linters ]

    for linter in linters
      @instance.addLinter(linter)

    new Disposable =>
      for linter in linters
        @instance.deleteLinter(linter)

  consumeStatusBar: (statusBar) ->
    @instance.views.attachBottom(statusBar)

  provideLinter: ->
    @instance

  deactivate: ->
    @instance?.deactivate()
