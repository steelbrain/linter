describe 'Commands', ->
  linter = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  describe 'linter:togglePanel', ->
    it 'toggles the panel visibility', ->
      visibility = linter.views.panel.getVisibility()
      linter.commands.togglePanel()
      expect(linter.views.panel.getVisibility()).toBe(!visibility)
      linter.commands.togglePanel()
      expect(linter.views.panel.getVisibility()).toBe(visibility)

  describe 'linter:toggle', ->
    it 'relint when enabled', ->
      waitsForPromise ->
        atom.workspace.open(__dirname + '/fixtures/file.txt').then ->
          spyOn(linter.commands, 'lint')
          linter.commands.toggleLinter()
          linter.commands.toggleLinter()
          expect(linter.commands.lint).toHaveBeenCalled()
