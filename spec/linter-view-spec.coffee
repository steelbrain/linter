sinon = require "sinon"
chai = require 'chai'
Editor = require atom.config.resourcePath + "/src/text-editor"

LinterView = require "../lib/linter-view.coffee"
Linter = require "../lib/linter.coffee"

expect = chai.expect


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
        inlineView =
          render: sinon.stub()
          remove: sinon.stub()
          hide: sinon.stub()
        linterView = new LinterView(
          editor
          statusBarView
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


describe "LinterView", ->

  lv = null
  stub_editor = sinon.createStubInstance(Editor)
  stub_editor.isAlive.returns(true)
  messages = [
    {line: 1, level: "info"},
    {line: 1, level: "error"},
    {line: 9, level: "warning"},
    {line: 9, level: "info"},
    {line: 3, level: "info"},
    {line: 20, level: "nonsense"}
  ]

  beforeEach ->
    sinon.stub(LinterView.prototype, 'initLinters')
    sinon.stub(LinterView.prototype, 'handleEditorEvents')
    sinon.stub(LinterView.prototype, 'updateViews')
    lv = new LinterView(stub_editor)

  afterEach ->
    LinterView.prototype.initLinters.restore()
    LinterView.prototype.handleEditorEvents.restore()
    LinterView.prototype.updateViews.restore()


  describe "message sorting", ->

    it "selects the most severe message for each line", ->
      lines = lv.sortMessagesByLine(messages)
      expect(lines['1'].level).to.equal(2)
      expect(lines['3'].level).to.equal(0)
      expect(lines['9'].level).to.equal(1)

    it "ignores messages of unrecognized levels", ->
      lines = lv.sortMessagesByLine(messages)
      expect(lines).to.not.property('20')


  describe "message display", ->

    it "bails if gutters and highlighting is turned off", ->
      lv.showGutters = lv.showHighlighting = false
      lv.display(messages)
      expect(lv.markers).to.not.exist

    it "creates markers for each line with a message", ->
      lv.showGutters = lv.showHighlighting = true
      lv.display(messages)
      expect(lv.markers).to.have.length(3)
