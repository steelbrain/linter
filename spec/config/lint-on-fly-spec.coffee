describe 'The Lint on the Fly Configuration Option', ->

  configString = 'linter.lintOnFly'

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it 'is `true` by default.', ->
    packageSetting = atom.config.get configString
    expect(packageSetting).toBe true
