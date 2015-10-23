describe 'The Lint as you Type Configuration Option', ->

  configString = 'linter.lintAsYouType'

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it 'is `true` by default.', ->
    packageSetting = atom.config.get configString
    expect(packageSetting).toBe true
