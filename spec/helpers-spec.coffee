Helpers = require '../lib/helpers'

describe "The Results Validation Helper", ->
  it "should throw an exception when nothing is passed.", ->
    expect( -> Helpers.validateResults()).toThrow()
  it "should throw an exception when a String is passed.", ->
    expect( -> Helpers.validateResults('String')).toThrow()

describe "The Linter Validation Helper", ->
  it "should throw an exception when grammarScopes is not an Array.", ->
    linter = {
      grammarScopes: 'not an array'
      lint: ->
    }
    expect( -> Helpers.validateLinter(linter)).toThrow()

  it "should throw an exception when lint is missing.", ->
    linter = {
      grammarScopes: []
    }
    expect( -> Helpers.validateLinter(linter)).toThrow()

  it "should throw an exception when a lint is not a function.", ->
    linter = {
      grammarScopes: []
      lint: 'not a function'
    }
    expect( -> Helpers.validateLinter(linter)).toThrow()
