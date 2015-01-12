sinon = require "sinon"

LinterView = require "../lib/linter-view.coffee"
Linter = require "../lib/linter.coffee"

describe "LinterView:lint", ->
  class CatFileLinter extends Linter
    @syntax: 'text.plain.null-grammar'
    cmd: 'cat'
    regex: '(?<line>[0-9]+):(?<message>.+)'
    constructor: (editor) ->
      super editor

  it "calls lintFile on each linter", ->
    linterClasses = [CatFileLinter, CatFileLinter]
    linterView = null

    waitsForPromise ->
      atom.workspace.open('./fixture/messages.txt').then (editor) ->
        statusBarView =
          render: sinon.stub()
          hide: sinon.stub()
        statusBarSummaryView =
          render: sinon.stub()
          remove: sinon.stub()
        inlineView =
          render: sinon.stub()
          remove: sinon.stub()
        linterView = new LinterView(
          editor
          statusBarView
          statusBarSummaryView
          inlineView
          linterClasses
        )
    calls = 0

    runs ->
      for linter in linterView.linters
        linter.lintFile = ->
          calls += 1
      linterView.lint()

    waitsFor ->
      calls is linterClasses.length
    , "lint file finished"
