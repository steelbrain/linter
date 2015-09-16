
{CompositeDisposable, Emitter} = require('atom')

BottomTab = require('./bottom-tab')
BottomStatus = require('./bottom-status')

class BottomContainer extends HTMLElement
  prepare: (@state) ->
    return this

  createdCallback: ->
    @subscriptions = new CompositeDisposable
    @emitter = emitter = new Emitter
    @tabs =
      Line: new BottomTab().prepare('Line')
      File: new BottomTab().prepare('File')
      Project: new BottomTab().prepare('Project')
    @status = new BottomStatus()
    Me = this

    @subscriptions.add atom.config.observe('linter.statusIconScope', (statusIconScope) =>
      @statusIconScope = statusIconScope
      @status.count = @tabs[@statusIconScope].count
    )

    for name, tab of @tabs
      @subscriptions.add atom.config.onDidChange("linter.showErrorTab#{name}", => @updateTabs())
      tab.addEventListener 'click', ->
        if Me.state.scope is @name
          emitter.emit 'should-toggle-panel'
        else
          emitter.emit 'did-change-tab', @name

    @onDidChangeTab (activeName) =>
      @state.scope = activeName
      for name, tab of @tabs
        tab.active = name is activeName

  attachedCallback: ->
    @updateTabs()

  detachedCallback: ->
    @subscriptions.dispose()
    @emitter.dispose()

  setVisibility: (value) ->
    if value
      this.removeAttribute('hidden')
    else
      this.setAttribute('hidden', true)

  getVisibility: ->
    !@hasAttribute('hidden')

  getTab: (name) ->
    return @tabs[name]

  onDidChangeTab: (callback) ->
    return @emitter.on 'did-change-tab', callback

  onShouldTogglePanel: (callback) ->
    return @emitter.on 'should-toggle-panel', callback

  setCount: ({Project, File, Line}) ->
    @tabs.File.count = File
    @tabs.Project.count = Project
    @tabs.Line.count = Line
    @status.count = @tabs[@statusIconScope].count

  updateTabs: ->
    active = @state.scope
    for name, tab of @tabs
      this.removeChild(tab) if tab.attached
      tab.active = false
      continue unless atom.config.get "linter.showErrorTab#{name}"
      @appendChild(tab)
      continue unless active is name
      tab.active = true
      active = null
    @appendChild(@status)
    if active is @state.scope and @firstChild and @firstChild.name
      @firstChild.active = true
      @state.scope = @firstChild.name

module.exports = document.registerElement('linter-bottom-container', {
  prototype: BottomContainer.prototype
})
