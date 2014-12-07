_ = require 'lodash'
fs = require 'fs'
temp = require 'temp'
path = require 'path'
{log, warn} = require './utils'
rimraf = require 'rimraf'
{CompositeDisposable} = require 'event-kit'


temp.track()

# Public: The base linter view
class LinterView

  fileMessages: {}
  views: []

  # Pubic: Instantiate the view
  constructor: ->
    @subscriptions = new CompositeDisposable

    @handleConfigChanges()

  # Internal: register config modifications handlers
  handleConfigChanges: ->
    @subscriptions.add atom.config.observe 'linter.showOnTabAndTreeView',
      (showOnTabAndTreeView) =>
        @showOnTabAndTreeView = showOnTabAndTreeView
        @display()

  updateViews: =>
    @views = []
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
      else
        memo
    ,''

  # Internal: Render all the linter messages
  display: ->
    if @showOnTabAndTreeView
      @updateViews()
      for file, messages of @fileMessages
        if messages
          @addFileLevelIndicator file, @getMessagesLevel messages
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
    for file of @messages
      @removeFileLevelIndicator(file)
    @subscriptions.dispose()

module.exports = LinterView
