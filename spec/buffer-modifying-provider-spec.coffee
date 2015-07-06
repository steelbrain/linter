describe 'buffer modifying linters', ->
  getModuleMain = -> atom.packages.getActivePackage('linter').mainModule.instance
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('status-bar')
      .catch (err)->
        console.log err
    waitsForPromise ->
      atom.packages.activatePackage('linter')
    waitsForPromise ->
      atom.workspace.open(__dirname + '/fixtures/test.txt')
  it 'is triggered before other linters', ->
    linter = getModuleMain()
    last = null
    normalLinter =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: false
      lint: ->
        last = 'normal'
        return []
    bufferModifying =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      modifiesBuffer: true
      lint: ->
        last = 'bufferModifying'
        return []
    linter.addLinter(normalLinter)
    linter.addLinter(bufferModifying)
    waitsForPromise ->
      linter.getActiveEditorLinter().lint(false).then ->
        expect(last).toBe('normal')