describe 'Linter Behavior', ->
  linter = null
  linterState = null
  bottomContainer = null
  {getLinter, trigger} = require('./common')

  getMessage = (type, filePath) ->
    return {type, text: 'Some Message', filePath, range: [[0, 0], [1, 1]]}

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
      # Set up errors.
      timesCalled = 0
      bottomContainer.onShouldTogglePanel -> ++timesCalled
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(timesCalled).toBe(0)
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(timesCalled).toBe(1)

    it 're-enables panel when another tab is clicked', ->
      # Set up errors.

      timesCalled = 0
      bottomContainer.onShouldTogglePanel -> ++timesCalled
      trigger(bottomContainer.getTab('File'), 'click')
      expect(timesCalled).toBe(1)
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(timesCalled).toBe(1)

    it 'updates count on pane change', ->
      provider = getLinter()
      expect(bottomContainer.getTab('File').count).toBe(0)
      messages = [getMessage('Error', __dirname + '/fixtures/file.txt')]
      linter.setMessages(provider, messages)
      linter.messages.updatePublic()
      waitsForPromise ->
        atom.workspace.open('file.txt').then ->
          expect(bottomContainer.getTab('File').count).toBe(1)
          expect(linter.views.bottomPanel.getVisibility()).toBe(true)
          atom.workspace.open('/tmp/non-existing-file')
        .then ->
          expect(bottomContainer.getTab('File').count).toBe(0)
          expect(linter.views.bottomPanel.getVisibility()).toBe(false)
