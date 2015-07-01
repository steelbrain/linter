Helpers = require '../lib/helpers'

describe "The Results Validation Helper", ->
  it "should throw an exception when nothing is passed.", ->
    expect( -> Helpers.validateResults()).toThrow()
  it "should throw an exception when a String is passed.", ->
    expect( -> Helpers.validateResults('String')).toThrow()
