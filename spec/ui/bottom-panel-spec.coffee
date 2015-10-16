describe 'BottomPanel', ->
  BottomPanel = require('../../lib/ui/bottom-panel')
  linter = null
  bottomPanel = null
  beforeEach ->
    bottomPanel?.dispose()
    bottomPanel = new BottomPanel('File')
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  {getMessage} = require('../common')

  it 'is not visible when there are no errors', ->
    expect(linter.views.bottomPanel.getVisibility()).toBe(false)

  it 'hides on config change', ->
    # Set up visibility.
    linter.views.bottomPanel.scope = 'Project'
    linter.views.bottomPanel.setMessages({added: [getMessage('Error')], removed: []})

    expect(linter.views.bottomPanel.getVisibility()).toBe(true)
    atom.config.set('linter.showErrorPanel', false)
    expect(linter.views.bottomPanel.getVisibility()).toBe(false)
    atom.config.set('linter.showErrorPanel', true)
    expect(linter.views.bottomPanel.getVisibility()).toBe(true)

  describe '{set, remove}Messages', ->
    it 'works as expected', ->
      messages = [getMessage('Error'), getMessage('Warning')]
      bottomPanel.setMessages({added: messages, removed: []})
      expect(bottomPanel.element.childNodes[0].childNodes.length).toBe(2)
      bottomPanel.setMessages({added: [], removed: messages})
      expect(bottomPanel.element.childNodes[0].childNodes.length).toBe(0)
      bottomPanel.setMessages({added: messages, removed: []})
      expect(bottomPanel.element.childNodes[0].childNodes.length).toBe(2)
      bottomPanel.removeMessages(messages)
      expect(bottomPanel.element.childNodes[0].childNodes.length).toBe(0)
