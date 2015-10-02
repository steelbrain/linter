describe 'validate', ->
  validate = require('../lib/validate')
  describe '::linter', ->
    it 'throws error if grammarScopes is not an array', ->
      expect ->
        validate.linter({lint: -> })
      .toThrow('grammarScopes is not an Array. Got: undefined')
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
      .toThrow('Expected messages to be array, provided: undefined')
      expect ->
        validate.messages(true)
      .toThrow('Expected messages to be array, provided: boolean')
    it 'throws if type field is not present', ->
      expect ->
        validate.messages([{}], {name: ''})
      .toThrow()
    it 'throws if type field is invalid', ->
      expect ->
        validate.messages([{type: 1}], {name: ''})
      .toThrow()
    it "throws if there's no html/text field on message", ->
      expect ->
        validate.messages([{type: 'Error'}], {name: ''})
      .toThrow()
    it 'throws if html/text is invalid', ->
      expect ->
        validate.messages([{type: 'Error', html: 1}], {name: ''})
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: 1}], {name: ''})
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', html: false}], {name: ''})
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: false}], {name: ''})
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', html: []}], {name: ''})
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: []}], {name: ''})
      .toThrow()
    it 'throws if trace is invalid', ->
      expect ->
        validate.messages([{type: 'Error', html: 'a', trace: 1}], {name: ''})
      .toThrow()
      validate.messages([{type: 'Error', html: 'a', trace: false}], {name: ''})
    it 'throws if class is invalid', ->
      expect ->
        validate.messages([{type: 'Error', text: 'Well', class: 1}], {name: ''})
      .toThrow()
      expect ->
        validate.messages([{type: 'Error', text: 'Well', class: []}], {name: ''})
      .toThrow()
      validate.messages([{type: 'Error', text: 'Well', class: 'error'}], {name: ''})
