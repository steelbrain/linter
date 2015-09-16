describe "The Status Bar Visibility Configuration Option", ->

  configString = "linter.displayLinterInfo"

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it "is `true` by default.", ->
    packageSetting = atom.config.get configString
    expect(packageSetting).toBe true
