describe 'Commands', ->
  linter = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  getMessage = (type, filePath) ->
    return {type, text: 'Some Message', filePath}

  describe 'linter:togglePanel', ->
    it 'toggles the panel visibility', ->
      # Set up visibility.
      linter.views.panel.scope = 'Project'
      linter.views.panel.setMessages({added: [getMessage('Error')], removed: []})

      visibility = linter.views.panel.getVisibility()
      expect(visibility).toBe(true)
      linter.commands.togglePanel()
      expect(linter.views.panel.getVisibility()).toBe(not visibility)
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
