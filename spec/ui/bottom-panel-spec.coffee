describe 'BottomPanel', ->
  BottomPanel = require('../../lib/ui/bottom-panel')
  linter = null
  bottomPanel = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance
        bottomPanel?.dispose()
        bottomPanel = new BottomPanel('File', linter.editors)
        atom.workspace.open(__dirname + '/fixtures/file.txt')

  {getMessage} = require('../common')

  it 'is not visible when there are no errors', ->
    expect(linter.views.bottomPanel.getVisibility()).toBe(false)

  it 'hides on config change', ->
    # Set up visibility.
    linter.views.bottomPanel.scope = 'Project'
    linter.getActiveEditorLinter().addMessage(getMessage('Error'))

    linter.views.bottomPanel.updateVisibility()
    expect(linter.views.bottomPanel.getVisibility()).toBe(true)
    atom.config.set('linter.showErrorPanel', false)
    linter.views.bottomPanel.updateVisibility()
    expect(linter.views.bottomPanel.getVisibility()).toBe(false)
    atom.config.set('linter.showErrorPanel', true)
    linter.views.bottomPanel.updateVisibility()
    expect(linter.views.bottomPanel.getVisibility()).toBe(true)
