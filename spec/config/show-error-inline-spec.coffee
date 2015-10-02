describe 'The Inline Tooltips Configuration Option', ->

  configString = 'linter.showErrorInline'

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it 'is `true` by default.', ->
    packageSetting = atom.config.get configString
    expect(packageSetting).toBe true
