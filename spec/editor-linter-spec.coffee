describe 'editor-linter', ->
  {getMessage, wait} = require('./common')
  EditorLinter = require('../lib/editor-linter')
  editorLinter = null
  textEditor = null

  beforeEach ->
    global.setTimeout = require('remote').getGlobal('setTimeout')
    global.setInterval = require('remote').getGlobal('setInterval')
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open(__dirname + '/fixtures/file.txt').then ->
        editorLinter?.dispose()
        textEditor = atom.workspace.getActiveTextEditor()
        editorLinter = new EditorLinter(textEditor)

  describe '::constructor', ->
    it "cries when provided argument isn't a TextEditor", ->
      expect ->
        new EditorLinter
      .toThrow()
      expect ->
        new EditorLinter(null)
      .toThrow()
      expect ->
        new EditorLinter(55)
      .toThrow()

  describe '::onShouldLint', ->
    it 'is triggered on save', ->
      timesTriggered = 0
      editorLinter.onShouldLint ->
        timesTriggered++
      textEditor.save()
      textEditor.save()
      textEditor.save()
      textEditor.save()
      textEditor.save()
      expect(timesTriggered).toBe(5)

  describe '::onDidDestroy', ->
    it 'is called when TextEditor is destroyed', ->
      didDestroy = false
      editorLinter.onDidDestroy ->
        didDestroy = true
      textEditor.destroy()
      expect(didDestroy).toBe(true)
