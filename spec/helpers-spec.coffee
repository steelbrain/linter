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

describe "The Command Execution Helper", ->
  it "should throw when no parameters are passed.", ->
    expect( -> Helpers.exec()).toThrow()
  it "should return the results when successful.", ->
    Helpers.exec("echo 'Test'").then (output) ->
      expect(output).toEqual(['Test\n'])


describe "The Command and FilePath Helper", ->
  it "should throw when no parametes are passed.", ->
    expect( -> Helpers.execFilePath()).toThrow()
  it "should throw when no File Path is passed.", ->
    expect( -> Helpers.execFilePath('echo')).toThrow()
  it "should return results when successful.", ->
    waitsForPromise -> atom.workspace.open 'test.txt'
    atom.workspace.observeTextEditors (editor) ->
      Helpers.execFilePath('cat', [], editor.getPath()).then (output) ->
        expect(output).toEqual(['This is a test.\n'])

  describe "The Regex Parsing Helper", ->
    it "should return Linter results when successful.", ->
      regex = 'type:(?<type>.+) message:(?<message>.+)'
      input = ['type:type message:message']
      output = [(
        type: 'type'
        text: 'message'
        filePath: undefined
        range: [[0, 0], [0, 0]]
      )]
      Helpers.parse(input, regex).then (results) ->
        expect(results).toEqual(output)
