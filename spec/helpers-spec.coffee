Helpers = require '../lib/helpers'

describe "The Results Validation Helper", ->
  it "should throw an exception when nothing is passed.", ->
    expect( -> Helpers.validateResults()).toThrow()
  it "should throw an exception when a String is passed.", ->
    expect( -> Helpers.validateResults('String')).toThrow()
  it "should throw an exception when a result's type is missing.", ->
    results = [{}]
    expect( -> Helpers.validateResults(results)).toThrow()
  it "should return the results when validated.", ->
    results = [{type: 'Type'}]
    expect(Helpers.validateResults(results)).toEqual(results)

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
  it "should return true when everything validates.", ->
    linter = {
      grammarScopes: []
      lint: ->
    }
    expect(Helpers.validateLinter(linter)).toEqual(true)
