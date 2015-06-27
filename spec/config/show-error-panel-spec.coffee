describe "The Error Panel Visibility Configuration Option", ->

  configString = "linter.showErrorPanel"

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it "is `true` by default.", ->
    packageSetting = atom.config.get configString
    expect(packageSetting).toBe true
