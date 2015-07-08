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
    exeOrder = []
    first =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        exeOrder.push('first')
        return []
    second =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        exeOrder.push('second')
        return []
    third =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        exeOrder.push('third')
        return []
    normalLinter =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: false
      lint: ->
        exeOrder.push('forth')
        return []
    linter.addLinter(first)
    linter.addLinter(second)
    linter.addLinter(third)
    linter.addLinter(normalLinter)
    waitsForPromise ->
      linter.getActiveEditorLinter().lint(false).then ->
        expect(exeOrder[0]).toBe('first')
        expect(exeOrder[1]).toBe('second')
        expect(exeOrder[2]).toBe('third')
        expect(exeOrder[3]).toBe('forth')