describe 'buffer modifying linter', ->
  linter = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then (pack) -> linter = pack.mainModule.instance
    waitsForPromise ->
      atom.workspace.open('test.txt')
  it 'triggers before other linters', ->
    last = null
    bufferModifying =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        last = 'bufferModifying'
        return []
    normalLinter =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: false
      lint: ->
        last = 'normal'
        return []
    linter.addLinter(bufferModifying)
    linter.addLinter(normalLinter)
    waitsForPromise ->
      linter.getActiveEditorLinter().lint(false).then ->
        expect(last).toBe('normal')
  it 'runs in sequence', ->
    activeEditor = atom.workspace.getActiveTextEditor()
    wasTriggered = false
    first =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        wasTriggered = true
        activeEditor.setText('first')
        return []
    second =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        expect(activeEditor.getText()).toBe('first')
        activeEditor.setText('second')
        return []
    third =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        expect(activeEditor.getText()).toBe('second')
        activeEditor.setText('third')
        return []
    normalLinter =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: false
      lint: ->
        expect(activeEditor.getText()).toBe('third')
        return []
    linter.addLinter(first)
    linter.addLinter(second)
    linter.addLinter(third)
    linter.addLinter(normalLinter)
    waitsForPromise ->
      linter.getActiveEditorLinter().lint(false).then ->
        expect(wasTriggered).toBe(true)