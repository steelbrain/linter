describe 'editor-linter', ->
  EditorLinter = require('../lib/editor-linter')
  editorLinter = null
  textEditor = null
  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('/tmp/test.txt').then ->
        editorLinter?.dispose()
        textEditor = atom.workspace.getActiveTextEditor()
        editorLinter = new EditorLinter(textEditor)

  describe '::constructor', ->
    it "cries when provided argument isn't a TextEditor", ->
      expect ->
        new EditorLinter
      .toThrow("Given editor isn't really an editor")
      expect ->
        new EditorLinter(null)
      .toThrow("Given editor isn't really an editor")
      expect ->
        new EditorLinter(55)
      .toThrow("Given editor isn't really an editor")

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
