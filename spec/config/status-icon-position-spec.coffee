describe "The Status Icon Configuration Option", ->

  configString = "linter.statusIconPosition"

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter')

  it "is 'Left' by default.", ->
    packageSetting = atom.config.get configString
    expectedDefault = "Left"
    expect(packageSetting).toEqual expectedDefault
