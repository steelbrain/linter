_ = require 'lodash'
fs = require 'fs'
temp = require 'temp'
path = require 'path'
{log, warn} = require './utils'
rimraf = require 'rimraf'
{CompositeDisposable, Emitter} = require 'event-kit'


temp.track()

# Public: The base linter view
class LinterView

  fileMessages: {}
  views: []

  # Pubic: Instantiate the views
  #
  # editor - the atom editor view on which to place highlighting and gutter
  #              annotations
  # statusBarView - shared StatusBarView between all linters
  # linters - global linter set to utilize for linting
  constructor: ->
    @subscriptions = new CompositeDisposable

    @handleConfigChanges()

  # Internal: register config modifications handlers
  handleConfigChanges: ->
    @subscriptions.add atom.config.observe 'linter.showOnTabAndTreeView',
      (showOnTabAndTreeView) =>
        @showOnTabAndTreeView = showOnTabAndTreeView
        @display()


    atom.commands.add "atom-text-editor",
      "linter:lint", => @lint()

  getViews: =>
    tabsPackage = atom.packages.getActivePackage('tabs')
    if tabsPackage?
      @views = @views.concat tabsPackage.requireMainModule()?.tabBarViews

    treeViewPackage = atom.packages.getActivePackage('tree-view')
    if treeViewPackage?
      @views.push treeViewPackage.requireMainModule()?.treeView

  updateFile: ({file, messages}) ->
    @fileMessages[file] = if messages.length > 0
      messages
    else
      false

    @display()

  getMessagesLevel: (messages) ->
    messages.reduce (memo, message) ->
      memo = if message.level == 'error'
        'error'
      else if message.level == 'warning' && memo != 'error'
        'warning'
    ,''

  # Internal: Render all the linter messages
  display: ->
    @getViews()
    if @showOnTabAndTreeView
      _.each @fileMessages, (messages, file) =>
        if messages
          messageLevel = @addFileLevelIndicator file, @getMessagesLevel messages
        else
          @removeFileLevelIndicator(file)

  getSelector: (file) ->
    '[data-path="' + file + '"]'

  removeFileLevelIndicator: (file) ->
    @views.forEach (view) =>
      view.find(@getSelector(file))
        .removeClass('linter-error')
        .removeClass('linter-warning')

  addFileLevelIndicator: (file, level) ->
    @views.forEach (view) =>
      view.find(@getSelector(file))
        .addClass('linter-' + level)

  # Public: remove this view and unregister all it's subscriptions
  remove: ->
    _.each @messages, (messages, file) =>
      @removeFileLevelIndicator(file)
    @subscriptions.dispose()

module.exports = LinterView
