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

  describe '::{add, remove}Message', ->
    it 'adds/removes decorations from the editor', ->
      countDecorations = textEditor.getDecorations().length
      editorLinter.underlineIssues = true
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      editorLinter.addMessage(message)
      expect(textEditor.getDecorations().length).toBe(countDecorations + 1)
      editorLinter.deleteMessage(message)
      expect(textEditor.getDecorations().length).toBe(countDecorations)

  describe '::getMessages', ->
    it 'returns a set of messages', ->
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      messageSet = editorLinter.getMessages()
      editorLinter.addMessage(message)
      expect(messageSet.has(message)).toBe(true)
      editorLinter.deleteMessage(message)
      expect(messageSet.has(message)).toBe(false)

  describe '::onDidMessage{Add, Change, Delete}', ->
    it 'notifies us of the changes to messages', ->
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      messageAdd = jasmine.createSpy('messageAdd')
      messageChange = jasmine.createSpy('messageChange')
      messageRemove = jasmine.createSpy('messageRemove')
      editorLinter.onDidMessageAdd(messageAdd)
      editorLinter.onDidMessageChange(messageChange)
      editorLinter.onDidMessageDelete(messageRemove)
      editorLinter.addMessage(message)
      expect(messageAdd).toHaveBeenCalled()
      expect(messageAdd).toHaveBeenCalledWith(message)
      expect(messageChange).toHaveBeenCalled()
      expect(messageChange.mostRecentCall.args[0].type).toBe('add')
      expect(messageChange.mostRecentCall.args[0].message).toBe(message)
      editorLinter.deleteMessage(message)
      expect(messageRemove).toHaveBeenCalled()
      expect(messageRemove).toHaveBeenCalledWith(message)
      expect(messageChange.mostRecentCall.args[0].type).toBe('delete')
      expect(messageChange.mostRecentCall.args[0].message).toBe(message)

  describe '::active', ->
    it 'updates currentFile attribute on the messages', ->
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      editorLinter.addMessage(message)
      expect(message.currentFile).toBe(true)
      editorLinter.active = false
      expect(message.currentFile).toBe(false)
      editorLinter.deleteMessage(message)
      editorLinter.addMessage(message)
      expect(message.currentFile).toBe(false)

  describe '::{calculateLineMessages, onDidCalculateLineMessages}', ->
    it 'works and also ignores', ->
      listener = jasmine.createSpy('onDidCalculateLineMessages')
      message = getMessage('Hey!', __dirname + '/fixtures/file.txt', [[0, 1], [0, 2]])
      editorLinter.addMessage(message)
      editorLinter.onDidCalculateLineMessages(listener)
      atom.config.set('linter.showErrorTabLine', true)
      expect(editorLinter.calculateLineMessages(0)).toBe(1)
      expect(editorLinter.countLineMessages).toBe(1)
      expect(listener).toHaveBeenCalledWith(1)
      atom.config.set('linter.showErrorTabLine', false)
      expect(editorLinter.calculateLineMessages(0)).toBe(0)
      expect(editorLinter.countLineMessages).toBe(0)
      expect(listener).toHaveBeenCalledWith(0)
      atom.config.set('linter.showErrorTabLine', true)
      expect(editorLinter.calculateLineMessages(0)).toBe(1)
      expect(editorLinter.countLineMessages).toBe(1)
      expect(listener).toHaveBeenCalledWith(1)

  describe '::{handle, add, remove}Gutter', ->
    it 'handles the attachment and detachment of gutter to text editor', ->
      editorLinter.gutterEnabled = false
      expect(editorLinter.gutter is null).toBe(true)
      editorLinter.gutterEnabled = true
      editorLinter.handleGutter()
      expect(editorLinter.gutter is null).toBe(false)
      editorLinter.gutterEnabled = false
      editorLinter.handleGutter()
      expect(editorLinter.gutter is null).toBe(true)
      editorLinter.addGutter()
      expect(editorLinter.gutter is null).toBe(false)
      editorLinter.removeGutter()
      expect(editorLinter.gutter is null).toBe(true)
      editorLinter.removeGutter()
      expect(editorLinter.gutter is null).toBe(true)

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
    it 'respects lintOnFlyInterval config', ->
      timeCalled = null
      flyStatus = null
      atom.config.set('linter.lintOnFlyInterval', 300)
      editorLinter.onShouldLint (fly) ->
        flyStatus = fly
        timeCalled = new Date()
      timeDid = new Date()
      editorLinter.editor.insertText("Hey\n")
      waitsForPromise ->
        wait(300).then ->
          expect(timeCalled isnt null).toBe(true)
          expect(flyStatus isnt null).toBe(true)
          expect(flyStatus).toBe(true)
          expect(timeCalled - timeDid).toBeLessThan(400)

          atom.config.set('linter.lintOnFlyInterval', 600)
          timeCalled = null
          flyStatus = null
          timeDid = new Date()
          editorLinter.editor.insertText("Hey\n")

          wait(600)
        .then ->
          expect(timeCalled isnt null).toBe(true)
          expect(flyStatus isnt null).toBe(true)
          expect(flyStatus).toBe(true)
          expect(timeCalled - timeDid).toBeGreaterThan(599)
          expect(timeCalled - timeDid).toBeLessThan(700)

  describe '::onDidDestroy', ->
    it 'is called when TextEditor is destroyed', ->
      didDestroy = false
      editorLinter.onDidDestroy ->
        didDestroy = true
      textEditor.destroy()
      expect(didDestroy).toBe(true)
