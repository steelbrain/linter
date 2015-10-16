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
      lintOnFly: false
      lint: ->
    lintOnFly =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: true
      lint: ->
    bufferModifying =
      grammarScopes: ['*']
      scope: 'file'
      lintOnFly: false
      lint: ->
    it 'accepts a wildcard grammarScope', ->
      expect(helpers.shouldTriggerLinter(normalLinter, false, ['*'])).toBe(true)
    it 'runs lintOnFly ones on both save and lintOnFly', ->
      expect(helpers.shouldTriggerLinter(lintOnFly, false, ['*'])).toBe(true)
      expect(helpers.shouldTriggerLinter(lintOnFly, true, ['*'])).toBe(true)
    it "doesn't run save ones on fly", ->
      expect(helpers.shouldTriggerLinter(normalLinter, true, ['*'])).toBe(false)
