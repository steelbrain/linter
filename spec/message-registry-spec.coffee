describe 'message-registry', ->
  MessageRegistry = require('../lib/message-registry')
  EditorLinter = require('../lib/editor-linter')
  LinterRegistry = require('../lib/linter-registry')
  nextAnimationFrame = ->
    return new Promise (resolve) -> requestAnimationFrame(resolve)
  getLinterRegistry = ->
    linterRegistry = new LinterRegistry
    editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
    linter = {
      grammarScopes: ['*']
      lintOnFly: false
      modifiesBuffer: false
      scope: 'file'
      lint: -> return [{type: "Error", text: "Something"}]
    }
    linterRegistry.addLinter(linter)
    return {linterRegistry, editorLinter}

  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt')

  describe '::constructor', ->
    it 'accepts not arguments', ->
      messageRegistry = new MessageRegistry()
      messageRegistry.deactivate()
      expect(true).toBe(true)

  describe '::set', ->
    it 'accepts info from LinterRegistry::lint', ->
      messageRegistry = new MessageRegistry()
      {linterRegistry, editorLinter} = getLinterRegistry()
      wasUpdated = false
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        wasUpdated = true
        messageRegistry.set(linterInfo)
        expect(messageRegistry.updated).toBe(true)
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          expect(wasUpdated).toBe(true)
          linterRegistry.deactivate()
          messageRegistry.deactivate()

  describe '::onDidUpdateMessages', ->
    it 'is triggered asyncly with results', ->
      messageRegistry = new MessageRegistry()
      {linterRegistry, editorLinter} = getLinterRegistry()
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        messageRegistry.set(linterInfo)
        expect(messageRegistry.updated).toBe(true)
      gotMessages = null
      messageRegistry.onDidUpdateMessages (messages) ->
        gotMessages = messages
      # TODO: Write this spec

  describe '::deleteEditorMessages', ->
    it 'removes messages for that editor', ->
      messageRegistry = new MessageRegistry()
      {linterRegistry, editorLinter} = getLinterRegistry()
      editor = editorLinter.editor
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        messageRegistry.set(linterInfo)
        expect(messageRegistry.updated).toBe(true)
      gotMessages = null
      messageRegistry.onDidUpdateMessages (messages) ->
        gotMessages = messages
        messageRegistry.deleteEditorMessages(editor)
      # TODO: Write this spec
