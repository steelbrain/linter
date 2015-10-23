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
      lintAsYouType: false
      lint: ->
    lintAsYouType =
      grammarScopes: ['*']
      scope: 'file'
      lintAsYouType: true
      lint: ->
    bufferModifying =
      grammarScopes: ['*']
      scope: 'file'
      lintAsYouType: false
      lint: ->
    it 'accepts a wildcard grammarScope', ->
      expect(helpers.shouldTriggerLinter(normalLinter, false, ['*'])).toBe(true)
    it 'runs lintAsYouType ones on both save and lintAsYouType', ->
      expect(helpers.shouldTriggerLinter(lintAsYouType, false, ['*'])).toBe(true)
      expect(helpers.shouldTriggerLinter(lintAsYouType, true, ['*'])).toBe(true)
    it "doesn't run save ones on lintAsYouType", ->
      expect(helpers.shouldTriggerLinter(normalLinter, true, ['*'])).toBe(false)
