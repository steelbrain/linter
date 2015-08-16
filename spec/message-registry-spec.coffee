describe 'message-registry', ->
  messageRegistry = null
  MessageRegistry = require('../lib/message-registry')
  EditorLinter = require('../lib/editor-linter')
  LinterRegistry = require('../lib/linter-registry')
  objectSize = (obj) ->
    size = 0
    size++ for value of obj
    return size
  getMessage = (type, filePath) ->
    return {type, text: "Some Message", filePath}
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
    return {linterRegistry, editorLinter, linter}

  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt').then ->
        messageRegistry?.dispose()
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
          linterRegistry.dispose()
    it 'ignores deactivated linters', ->
      {linterRegistry, editorLinter, linter} = getLinterRegistry()
      messageRegistry.set({linter, messages: [getMessage('Error'), getMessage('Warning')]})
      messageRegistry.updatePublic()
      expect(messageRegistry.publicMessages.length).toBe(2)
      linter.deactivated = true
      messageRegistry.set({linter, messages: [getMessage('Error')]})
      messageRegistry.updatePublic()
      expect(messageRegistry.publicMessages.length).toBe(2)
      linter.deactivated = false
      messageRegistry.set({linter, messages: [getMessage('Error')]})
      messageRegistry.updatePublic()
      expect(messageRegistry.publicMessages.length).toBe(1)

  describe '::onDidUpdateMessages', ->
    it 'is triggered asyncly with results and provides a diff', ->
      wasUpdated = false
      {linterRegistry, editorLinter} = getLinterRegistry()
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        messageRegistry.set(linterInfo)
        expect(messageRegistry.hasChanged).toBe(true)
        messageRegistry.updatePublic()
      messageRegistry.onDidUpdateMessages ({added, removed, messages}) ->
        wasUpdated = true
        expect(added.length).toBe(1)
        expect(removed.length).toBe(0)
        expect(messages.length).toBe(1)
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          expect(wasUpdated).toBe(true)
          linterRegistry.dispose()
    it 'provides the same objects when they dont change', ->
      wasUpdated = false
      {linterRegistry, editorLinter} = getLinterRegistry()
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        messageRegistry.set(linterInfo)
        messageRegistry.updatePublic()
      disposable = messageRegistry.onDidUpdateMessages ({added}) ->
        expect(added.length).toBe(1)
        obj = added[0]
        disposable.dispose()
        messageRegistry.onDidUpdateMessages ({messages}) ->
          wasUpdated = true
          expect(messages[0]).toBe(obj)
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then( ->
          return linterRegistry.lint({onChange: false, editorLinter})
        ).then ->
          expect(wasUpdated).toBe(true)
          linterRegistry.dispose()

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
          linterRegistry.dispose()
