BottomTab = require './bottom-tab'
{Emitter} = require 'atom'

class TabContainer extends HTMLElement
  tabPriorities:
    Line:
      focus: 30
      order: 10
    File:
      focus: 10
      order: 20
    Project:
      focus: 20
      order: 30

  emitter: null
  tabs: null

  activeTab: ''

  constructor: ->

  initialize: ({@activeTab} = {}) ->
    if @activeTab
      @changeTab @activeTab

    # if there is no tab named @activeTab, then @activeTab will be ''
    # after @changeTab @activeTab
    if atom.config.get('linter.showErrorPanel')
      unless @activeTab
        @activateSomeTab()

  serialize: -> {@activeTab}

  createdCallback: ->
    @emitter = new Emitter()
    @tabs = new Map()

    @activeTab = ''

    for tabName of @tabPriorities
      @insertTab tabName if atom.config.get("linter.showErrorTab#{tabName}")

  destroy: ->
    @tabs.clear()
    @tabs = null

    @emitter.dispose()
    @emitter = null

  insertTab: (title) ->
    return @tabs.get title if @tabs.has title

    tabOrder = (tabTitle) =>
      @tabPriorities[tabTitle]?.order ? 100
    newOrder = tabOrder title # insert unknown tabs at end

    newTab = new BottomTab()
    newTab.initialize title, => @changeTab(title)

    @tabs.set title, newTab

    for child in @children
      if (tabOrder child.title) >= newOrder
        return @insertBefore newTab, child

    # if element with higher priority not found
    return @appendChild newTab

  removeTab: (title) ->
    return unless @tabs.has title

    wasActive = @getActiveTab()?

    @tabs.delete title

    for child in @children
      if child.title is title
        @removeChild child
        break

    if wasActive
      @activateSomeTab()

  getActiveTab: ->
    return @tabs.get @activeTab

  activateSomeTab: ->
    return if @getActiveTab()?
    tabs = (title for {title} in @children)
    [first] =
      tabs.sort (a, b) => @tabPriorities[a].focus - @tabPriorities[b].focus
    first ?= 'File'
    @changeTab first

  getTab: (title) ->
    return @tabs.get title

  changeTab: (title) ->
    someActive = false
    for child in @children
      child.active = (child.title is title) and not child.active
      someActive = someActive or child.active
    @activeTab = if someActive then title else ''
    @emitter.emit 'did-change-tab', {title, showPanel: someActive}

  onDidChangeTab: (callback) ->
    @emitter.on 'did-change-tab', callback

module.exports = TabContainer = document.registerElement('linter-tab-container', {
  prototype: TabContainer.prototype
})
