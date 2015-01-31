Linter = require "../lib/linter.coffee"
sinon = require "sinon"

{Range, Point} = require 'atom'

describe "Linter::computeRange", ->
  [linter, scopesForPosition, rangeForScopeAtPosition, lineLengthForRow] = []

  beforeEach ->
    linter = new Linter(
      getPath: -> "path"
      getLineCount: -> 10
    )
    scopesForPosition = sinon.stub linter, "getEditorScopesForPosition"
    rangeForScopeAtPosition = sinon.stub linter, "getGetRangeForScopeAtPosition"
    lineLengthForRow = sinon.stub linter, "lineLengthForRow"

  it "should return a complete range if all parameters provided, switched to zero index", ->
    range = linter.computeRange(
      colStart: "1",
      colEnd: "3",
      lineStart: "1",
      lineEnd: "2"
    )
    expect(range.serialize()).toEqual([[0, 0], [1, 2]])

  it "should support only getting a line number", ->
    range = linter.computeRange(
      colStart: "1",
      colEnd: "3",
      line: "1"
    )
    expect(range.serialize()).toEqual([[0, 0], [0, 2]])

  it "should support only getting a col number and retrieve range based on scope", ->
    scopesForPosition.returns(["scope.function"])
    rangeForScopeAtPosition.returns(new Range([0, 3], [2, 3]))

    range = linter.computeRange(
      col: "1",
      line: "1"
    )

    sinon.assert.calledWith rangeForScopeAtPosition, "scope.function"

    expect(range.serialize()).toEqual([[0, 3], [2, 3]])

  it "should support only getting a col number and use full line when no scope is found", ->
    scopesForPosition.returns([])
    lineLengthForRow.returns(20)

    range = linter.computeRange(
      col: "1",
      line: "1"
    )

    sinon.assert.notCalled rangeForScopeAtPosition
    sinon.assert.calledWith lineLengthForRow, 0
    expect(range.serialize()).toEqual([[0, 0], [0, 20]])

  it "should ensure a range off the end of a line is visible", ->
    lineLengthForRow.returns(20)

    # this kind of unusual match is returned by linter-jshint for a missing
    # semi-colon
    range = linter.computeRange
      colStart: "21",
      line: "1"

    expect(range.serialize()).toEqual([[0, 19], [0, 20]])


describe "Linter:lintFile", ->
  [linter] = []

  class CatFileLinter extends Linter
    cmd: 'cat'
    regex: '(?<line>[0-9]+):(?<message>.+)'
    constructor: (editor) ->
      super editor

  beforeEach ->
    waitsForPromise ->
      atom.workspace.open('linter-spec.coffee').then (editor) ->
        linter = new CatFileLinter(editor)

  it "lints file whose name is without space", ->
    flag = false

    runs ->
      linter.lintFile "fixture/messages.txt", (messages) ->
        console.log messages
        expect(messages.length).toBe(2)
        flag = true

    waitsFor ->
      flag
    , "lint file finished"

  it "lints file whose name is with space", ->
    flag = false

    runs ->
      linter.lintFile "fixture/messages with space.txt", (messages) ->
        console.log messages
        expect(messages.length).toBe(2)
        flag = true

    waitsFor ->
      flag
    , "lint file finished"

  it "lints when command is an array", ->
    flag = false

    runs ->
      linter.cmd = ['cat']
      linter.lintFile "fixture/messages.txt", (messages) ->
        console.log messages
        expect(messages.length).toBe(2)
        flag = true

    waitsFor ->
      flag
    , "lint file finished"

  it "lints when command is an array with arguments containing spaces", ->
    flag = false

    runs ->
      linter.cmd = ['cat', 'fixture/messages with space.txt']
      linter.lintFile "fixture/messages.txt", (messages) ->
        console.log messages
        expect(messages.length).toBe(4)
        flag = true

    waitsFor ->
      flag
    , "lint file finished"

  it "lints when executablePath is a directory", ->
    flag = false
    linter.cmd = ['cat']
    linter.executablePath = '/bin'

    runs ->
      linter.lintFile "fixture/messages.txt", ->
        flag = true

    waitsFor ->
      flag
    , "lint file finished"

  it "lints when executablePath is an executable", ->
    flag = false
    linter.cmd = ['notcat']
    linter.executablePath = '/bin/cat'

    runs ->
      linter.lintFile "fixture/messages.txt", ->
        flag = true

    waitsFor ->
      flag
    , "lint file finished"
