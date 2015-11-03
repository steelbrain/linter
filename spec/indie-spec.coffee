describe 'Indie', ->
  Validate = require('../lib/validate')
  Indie = require('../lib/indie')
  indie = null

  beforeEach ->
    indie?.dispose()
    indie = new Indie({})

  describe 'Validations', ->
    it 'just cares about a name', ->
      linter = {}
      Validate.linter(linter, true)
      expect(linter.name).toBe(null)
      linter.name = 'a'
      Validate.linter(linter, true)
      expect(linter.name).toBe('a')
      linter.name = 2
      expect ->
        Validate.linter(linter, true)
      .toThrow()

  describe 'constructor', ->
    it 'sets a scope for message registry to know', ->
      expect(indie.scope).toBe('project')
