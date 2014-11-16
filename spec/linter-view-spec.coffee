sinon = require "sinon"

{WorkspaceView} = require 'atom'

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
      atom.workspaceView = new WorkspaceView()
      atom.workspace.open('./fixture/messages.txt').then (editor) ->
        # TODO: surely there's a better way to mock this. Maybe I can use
        # a real TextEditorView.
        editorView =
          editor: editor
          getModel: -> editor
          on: sinon.stub()
          getPaneView: ->
            getModel: ->
              onDidRemoveItem: sinon.stub()
              onDidChangeActive: sinon.stub()
        editorView = editorView
        statusBarView =
          render: sinon.stub()
          hide: sinon.stub()
        inlineView =
          render: sinon.stub()
          hide: sinon.stub()
        linterView = new LinterView(
          editorView
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
