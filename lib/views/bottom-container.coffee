
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

    for name, tab of @tabs
      @subscriptions.add atom.config.onDidChange("linter.showErrorTab#{name}", @updateTabs.bind(@))
      tab.addEventListener 'click', ->
        emitter.emit 'did-change-tab', @name

  attachedCallback: ->
    @updateTabs()

  detachedCallback: ->
    @subscriptions.dispose()
    @emitter.dispose()

  onDidChangeTab: (callback) ->
    return @emitter.on 'did-change-tab', callback

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
