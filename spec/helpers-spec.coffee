describe 'helpers', ->
  helpers = require('../lib/helpers')
  beforeEach ->
    atom.notifications.clear()

  describe '::error', ->
    it 'adds an error notification', ->
      helpers.error(new Error())
      expect(atom.notifications.getNotifications().length).toBe(1)

  describe '::shouldTriggerLinter', ->
    normalLinter =
      grammarScopes: ['*']
      scope: 'file'
      modifiesBuffer: false
      lintOnFly: false
      lint: ->
    lintOnFly =
      grammarScopes: ['*']
      scope: 'file'
      modifiesBuffer: false
      lintOnFly: true
      lint: ->
    bufferModifying =
      grammarScopes: ['*']
      scope: 'file'
      modifiesBuffer: true
      lintOnFly: false
      lint: ->
    it 'accepts a wildcard grammarScope', ->
      expect(helpers.shouldTriggerLinter(normalLinter, false, false, ['*'])).toBe(true)
    it 'runs lintOnFly ones on both save and lintOnFly', ->
      expect(helpers.shouldTriggerLinter(lintOnFly, false, false, ['*'])).toBe(true)
      expect(helpers.shouldTriggerLinter(lintOnFly, false, true, ['*'])).toBe(true)
    it "doesn't run save ones on fly", ->
      expect(helpers.shouldTriggerLinter(normalLinter, false, true, ['*'])).toBe(false)
    it 'runs only if bufferModifying flag matches with linter', ->
      expect(helpers.shouldTriggerLinter(normalLinter, false, false, ['*'])).toBe(true)
      expect(helpers.shouldTriggerLinter(normalLinter, true, false, ['*'])).toBe(false)
      expect(helpers.shouldTriggerLinter(bufferModifying, false, false, ['*'])).toBe(false)
      expect(helpers.shouldTriggerLinter(bufferModifying, true, false, ['*'])).toBe(true)
