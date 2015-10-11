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
      .then ->
        atom.workspace.open(__dirname + '/../fixtures/file.txt')

  {getMessage, getLinter} = require('../common')

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

    it 'sorts messages', ->
      bottomPanel.scope = 'Project'
      atom.config.set('linter.sortMessages', true)
      path = __dirname + '/../fixtures/file.txt'
      bottomPanel.setMessages({removed: [], added: [
        getMessage('Error', path, [[0, 0], [0, 1]]),
        getMessage('Error', path, [[2, 0], [2, 1]]),
        getMessage('Error', path, [[1, 0], [1, 1]]),
        getMessage('Error', path, [[5, 0], [5, 1]]),
        getMessage('Error', path, [[3, 0], [3, 1]]),
        getMessage('Error', '/tmp/test', [[1, 0], [1, 1]]),
      ]})
      Array.prototype.forEach.call(bottomPanel.messagesElement.childNodes, (entry) ->
        entry.attachedCallback?() # No idea why but Custom Elements' attachedCallback is not triggered in test suite
      )
      expect(bottomPanel.messagesElement.childNodes[0].textContent).toContain('line 2 col 1')
      expect(bottomPanel.messagesElement.childNodes[0].textContent).toContain('/tmp/test')
      expect(bottomPanel.messagesElement.childNodes[1].textContent).toContain('line 1 col 1')
      expect(bottomPanel.messagesElement.childNodes[2].textContent).toContain('line 2 col 1')
      expect(bottomPanel.messagesElement.childNodes[3].textContent).toContain('line 3 col 1')
      expect(bottomPanel.messagesElement.childNodes[4].textContent).toContain('line 4 col 1')
      expect(bottomPanel.messagesElement.childNodes[5].textContent).toContain('line 6 col 1')
      expect(bottomPanel.messagesElement.childNodes.length).toBe(6)

