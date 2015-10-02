describe 'The Issue Underline Configuration Option', ->

  configString = 'linter.underlineIssues'

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it 'is `true` by default.', ->
    packageSetting = atom.config.get configString
    expect(packageSetting).toBe true
