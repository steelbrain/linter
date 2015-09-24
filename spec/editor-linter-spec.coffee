describe 'editor-linter', ->
  {getMessage} = require('./common')
  EditorLinter = require('../lib/editor-linter')
  editorLinter = null
  textEditor = null
  beforeEach ->
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

  describe '::{add, remove}Message', ->
    it 'adds/removes decorations from the editor', ->
      countDecorations = textEditor.getDecorations().length
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      editorLinter.addMessage(message)
      expect(textEditor.getDecorations().length).toBe(countDecorations + 1)
      editorLinter.removeMessage(message)
      expect(textEditor.getDecorations().length).toBe(countDecorations)

  describe '::onShouldLint', ->
    it 'ignores instant save requests', ->
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
