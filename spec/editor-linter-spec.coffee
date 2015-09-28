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
      editorLinter.underlineIssues = true
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      editorLinter.addMessage(message)
      expect(textEditor.getDecorations().length).toBe(countDecorations + 1)
      editorLinter.removeMessage(message)
      expect(textEditor.getDecorations().length).toBe(countDecorations)

  describe '::getMessages', ->
    it 'returns a set of messages', ->
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      messageSet = editorLinter.getMessages()
      editorLinter.addMessage(message)
      expect(messageSet.has(message)).toBe(true)
      editorLinter.removeMessage(message)
      expect(messageSet.has(message)).toBe(false)

  describe '::onDidMessage*', ->
    it 'notifies us of the changes to messages', ->
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      messageAdd = jasmine.createSpy('messageAdd')
      messageChange = jasmine.createSpy('messageChange')
      messageRemove = jasmine.createSpy('messageRemove')
      editorLinter.onDidMessageAdd(messageAdd)
      editorLinter.onDidMessageChange(messageChange)
      editorLinter.onDidMessageRemove(messageRemove)
      editorLinter.addMessage(message)
      expect(messageAdd).toHaveBeenCalled()
      expect(messageAdd).toHaveBeenCalledWith(message)
      expect(messageChange).toHaveBeenCalled()
      expect(messageChange.mostRecentCall.args[0].type).toBe('add')
      expect(messageChange.mostRecentCall.args[0].message).toBe(message)
      editorLinter.removeMessage(message)
      expect(messageRemove).toHaveBeenCalled()
      expect(messageRemove).toHaveBeenCalledWith(message)
      expect(messageChange.mostRecentCall.args[0].type).toBe('remove')
      expect(messageChange.mostRecentCall.args[0].message).toBe(message)

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
