describe 'editor-linter', ->
  EditorLinter = require('../lib/editor-linter')
  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt')
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
      textEditor = atom.workspace.getActiveTextEditor()
      editorLinter = new EditorLinter(textEditor)
      timesTriggered = 0
      editorLinter.onShouldLint ->
        timesTriggered++
      textEditor.save()
      textEditor.save()
      textEditor.save()
      textEditor.save()
      textEditor.save()
      expect(timesTriggered).toBe(5)
      editorLinter.deactivate()
  describe '::onDidDestroy', ->
    it 'is called when TextEditor is destroyed', ->
      textEditor = atom.workspace.getActiveTextEditor()
      editorLinter = new EditorLinter(textEditor)
      didDestroy = false
      editorLinter.onDidDestroy ->
        didDestroy = true
      textEditor.destroy()
      editorLinter.deactivate()
      expect(didDestroy).toBe(true)
