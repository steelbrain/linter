describe 'Linter Behavior', ->
  linter = null
  linterState = null
  bottomContainer = null
  trigger = (el, name) ->
    event = document.createEvent('HTMLEvents');
    event.initEvent(name, true, false);
    el.dispatchEvent(event);


  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance
        linterState = linter.state
        bottomContainer = linter.views.bottomContainer

  describe 'Bottom Tabs', ->
    it 'defaults to file tab', ->
      expect(linterState.scope).toBe('File')

    it 'changes tab on click', ->
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(linterState.scope).toBe('Project')

    it 'toggles panel visibility on click', ->
      expect(linter.views.panel.panelVisibility).toBe(true)
      trigger(bottomContainer.getTab('File'), 'click')
      expect(linter.views.panel.panelVisibility).toBe(false)
      trigger(bottomContainer.getTab('File'), 'click')
      expect(linter.views.panel.panelVisibility).toBe(true)
