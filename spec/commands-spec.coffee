describe 'Commands', ->
  linter = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance
        atom.workspace.open(__dirname + '/fixtures/file.txt')

  {getMessage} = require('./common')

  describe 'linter:togglePanel', ->
    it 'toggles the panel visibility', ->
      # Set up visibility.
      linter.views.bottomPanel.scope = 'Project'
      linter.getActiveEditorLinter().addMessage(getMessage('Error'))
      linter.views.render({added: [getMessage('Error')], removed: [], messages: []})

      visibility = linter.views.bottomPanel.getVisibility()
      expect(visibility).toBe(true)
      linter.commands.togglePanel()
      expect(linter.views.bottomPanel.getVisibility()).toBe(not visibility)
      linter.commands.togglePanel()
      expect(linter.views.bottomPanel.getVisibility()).toBe(visibility)

  describe 'linter:toggle', ->
    it 'relint when enabled', ->
      waitsForPromise ->
        atom.workspace.open(__dirname + '/fixtures/file.txt').then ->
          spyOn(linter.commands, 'lint')
          linter.commands.toggleLinter()
          linter.commands.toggleLinter()
          expect(linter.commands.lint).toHaveBeenCalled()
