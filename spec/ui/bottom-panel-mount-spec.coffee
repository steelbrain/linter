describe 'BottomPanelMount', ->
  [statusBar, statusBarService, workspaceElement] = []
  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage('status-bar').then (pack) ->
        statusBar = workspaceElement.querySelector('status-bar')
        statusBarService = pack.mainModule.provideStatusBar()
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        atom.packages.getActivePackage('linter').mainModule.consumeStatusBar(statusBar)
    waitsForPromise ->
      atom.workspace.open()

  it 'can mount to left status-bar', ->
    tile = statusBar.getLeftTiles()[0]
    expect(tile.item.localName).toBe('linter-bottom-container')

  it 'can mount to right status-bar', ->
    atom.config.set('linter.statusIconPosition', 'Right')
    tile = statusBar.getRightTiles()[0]
    expect(tile.item.localName).toBe('linter-bottom-container')

  it 'defaults to visible', ->
    tile = statusBar.getLeftTiles()[0]
    expect(tile.item.visibility).toBe(true)
