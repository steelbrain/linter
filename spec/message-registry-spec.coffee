describe 'message-registry', ->
  messageRegistry = null
  MessageRegistry = require('../lib/message-registry')
  EditorLinter = require('../lib/editor-linter')
  LinterRegistry = require('../lib/linter-registry')
  objectSize = (obj) ->
    size = 0
    size++ for value of obj
    return size
  getLinterRegistry = ->
    linterRegistry = new LinterRegistry
    editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
    linter = {
      grammarScopes: ['*']
      lintOnFly: false
      modifiesBuffer: false
      scope: 'project'
      lint: -> return [{type: "Error", text: "Something"}]
    }
    linterRegistry.addLinter(linter)
    return {linterRegistry, editorLinter}

  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt').then ->
        messageRegistry?.deactivate()
        messageRegistry = new MessageRegistry()

  describe '::set', ->
    it 'accepts info from LinterRegistry::lint', ->
      {linterRegistry, editorLinter} = getLinterRegistry()
      wasUpdated = false
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        wasUpdated = true
        messageRegistry.set(linterInfo)
        expect(messageRegistry.hasChanged).toBe(true)
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          expect(wasUpdated).toBe(true)
          linterRegistry.deactivate()

  describe '::onDidUpdateMessages', ->
    it 'is triggered asyncly with results', ->
      wasUpdated = false
      {linterRegistry, editorLinter} = getLinterRegistry()
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        messageRegistry.set(linterInfo)
        expect(messageRegistry.hasChanged).toBe(true)
        messageRegistry.updatePublic()
      gotMessages = null
      messageRegistry.onDidUpdateMessages (messages) ->
        wasUpdated = true
        gotMessages = messages
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          expect(wasUpdated).toBe(true)
          linterRegistry.deactivate()

  describe '::deleteEditorMessages', ->
    it 'removes messages for that editor', ->
      wasUpdated = 0
      {linterRegistry, editorLinter} = getLinterRegistry()
      editor = editorLinter.editor
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        messageRegistry.set(linterInfo)
        expect(messageRegistry.hasChanged).toBe(true)
        messageRegistry.updatePublic()
      messageRegistry.onDidUpdateMessages ({messages}) ->
        wasUpdated = 1
        expect(objectSize(messages)).toBe(1)
        messageRegistry.deleteEditorMessages(editor)
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          expect(wasUpdated).toBe(1)
          linterRegistry.deactivate()
