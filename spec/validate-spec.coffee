describe 'validate', ->
  validate = require('../lib/validate')
  describe '::linter', ->
    it 'throws error if grammarScopes is not an array', ->
      expect ->
        validate.linter({lint: -> })
      .toThrow("grammarScopes is not an Array. Got: undefined")
    it 'throws if lint is missing', ->
      expect ->
        validate.linter({grammarScopes: []})
      .toThrow("Missing linter.lint")
    it 'throws if lint is not a function', ->
      expect ->
        validate.linter({grammarScopes: [], lint: true})
      .toThrow("linter.lint isn't a function")

  describe '::messages', ->
    it 'throws if messages is not an array', ->
      expect ->
        validate.messages()
      .toThrow("Expected messages to be array, provided: undefined")
      expect ->
        validate.messages(true)
      .toThrow("Expected messages to be array, provided: boolean")
    it 'throws if type field is not present', ->
      expect ->
        validate.messages([{}])
      .toThrow("Missing type field on Linter Response")
    it "throws if there's no html/text field on message", ->
      expect ->
        validate.messages([{type: 'Error'}])
      .toThrow('Missing html/text field on Linter Response')
