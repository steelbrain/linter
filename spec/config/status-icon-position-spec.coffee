BottomTab = require '../../lib/views/bottom-tab'

describe "The Status Icon Configuration Option", ->
  [statusBar, workspaceElement, dummyView] = []
  configString = "linter.statusIconPosition"

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    dummyView = document.createElement("div")
    statusBar = null

    waitsForPromise ->
      atom.packages.activatePackage('linter')
    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

    runs ->
      statusBar = workspaceElement.querySelector("status-bar")

  it "is 'Left' by default.", ->
    expect(atom.config.get(configString)).toEqual "Left"

  describe "when set to 'Left'", ->
    beforeEach ->
      atom.config.set configString, 'Left'

    it "is set to 'Left.'", ->
      expect(atom.config.get(configString)).toEqual "Left"

    it "is on the left side of the Status Bar.", ->
      jasmine.attachToDOM(workspaceElement)
      [linterHighlight] = statusBar.getLeftTiles().map (tile) -> tile.getItem()
      expect(linterHighlight).toBeDefined
      [linterHighlight] = statusBar.getRightTiles().map (tile) -> tile.getItem()
      expect(linterHighlight).not.toBeDefined

  describe "when set to 'Right'", ->
    beforeEach ->
      atom.config.set configString, 'Right'

    it "is set to 'Right.'", ->
      expect(atom.config.get(configString)).toEqual "Right"

    it "is on the right side of the Status Bar.", ->
      jasmine.attachToDOM(workspaceElement)
      [linterHighlight] = statusBar.getRightTiles().map (tile) -> tile.getItem()
      expect(linterHighlight).toBeDefined
      [linterHighlight] = statusBar.getRightTiles().map (tile) -> tile.getItem()
      expect(linterHighlight).not.toBeDefined
