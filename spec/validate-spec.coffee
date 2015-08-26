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
      .toThrow()
    it 'throws if lint is not a function', ->
      expect ->
        validate.linter({grammarScopes: [], lint: true})
      .toThrow()

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
      .toThrow()
    it "throws if type field is invalid", ->
      expect ->
        validate.messages([{type: 1}])
      .toThrow()
    it "throws if there's no html/text field on message", ->
      expect ->
        validate.messages([{type: 'Error'}])
      .toThrow()
    it "throws if html/text is invalid", ->
      expect ->
        validate.messages([{type: 'Error', html: 1}])
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: 1}])
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', html: false}])
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: false}])
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', html: []}])
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: []}])
      .toThrow()
