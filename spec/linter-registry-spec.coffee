describe 'linter-registry', ->
  LinterRegistry = require('../lib/linter-registry')
  EditorLinter = require('../lib/editor-linter')
  editor = null
  linterRegistry = null
  {getLinter, getMessage} = require('./common')

  beforeEach ->
    atom.workspace.destroyActivePaneItem()
    waitsForPromise ->
      atom.workspace.open('file.txt').then ->
        editor = atom.workspace.getActiveTextEditor()
    waitsForPromise ->
      atom.packages.activatePackage('linter')
    linterRegistry?.dispose()
    linterRegistry = new LinterRegistry

  describe '::addLinter', ->
    it 'adds error notification if linter is invalid', ->
      linterRegistry.addLinter({})
      expect(atom.notifications.getNotifications().length).toBe(1)
    it 'pushes linter into registry when valid', ->
      linter = getLinter()
      linterRegistry.addLinter(linter)
      expect(linterRegistry.linters.size).toBe(1)
    it 'set deactivated to false on linter', ->
      linter = getLinter()
      linterRegistry.addLinter(linter)
      expect(linter.deactivated).toBe(false)

  describe '::hasLinter', ->
    it 'returns true if present', ->
      linter = getLinter()
      linterRegistry.addLinter(linter)
      expect(linterRegistry.hasLinter(linter)).toBe(true)
    it 'returns false if not', ->
      linter = getLinter()
      expect(linterRegistry.hasLinter(linter)).toBe(false)

  describe '::deleteLinter', ->
    it 'deletes the linter from registry', ->
      linter = getLinter()
      linterRegistry.addLinter(linter)
      expect(linterRegistry.hasLinter(linter)).toBe(true)
      linterRegistry.deleteLinter(linter)
      expect(linterRegistry.hasLinter(linter)).toBe(false)
    it 'sets deactivated to true on linter', ->
      linter = getLinter()
      linterRegistry.addLinter(linter)
      linterRegistry.deleteLinter(linter)
      expect(linter.deactivated).toBe(true)

  describe '::lint', ->
    it "doesn't lint if textEditor isn't active one", ->
      editorLinter = new EditorLinter(editor)
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        modifiesBuffer: false
        scope: 'file'
        lint: ->
      }
      linterRegistry.addLinter(linter)
      waitsForPromise ->
        atom.workspace.open('test2.txt').then ->
          linterRegistry.lint({onChange: false, editor}).then (result) ->
            expect(result).toBe(false)
    it "doesn't lint if textEditor doesn't have a path", ->
      editorLinter = new EditorLinter(editor)
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        scope: 'file'
        lint: ->
          return []
      }
      linterRegistry.addLinter(linter)
      waitsForPromise ->
        atom.workspace.open('someNonExistingFile.txt').then ->
          linterRegistry.lint({onChange: false, editor}).then (result) ->
            expect(result).toBe(false)
    it 'only uses results from the latest invocation', ->
      time = 0
      messagesUpdated = false
      editorLinter = new EditorLinter(editor)
      message = getMessage('Error')
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        scope: 'file'
        lint: ->
          time++
          if time is 1
            return []
          else
            return [message]
      }
      linterRegistry.addLinter(linter)
      linterRegistry.onDidUpdateMessages (result) ->
        expect(result.messages[0]).toBe(message)
        messagesUpdated = true
      linterRegistry.lint({onChange: false, editor})
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editor}).then (result) ->
          expect(result).toBe(true)
          expect(time).toBe(2)
          expect(messagesUpdated).toBe(true)
    it 'only sets messages of active linters', ->
      called = 0
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        scope: 'file'
        lint: ->
      }
      linterRegistry.onDidUpdateMessages ->
        called++
      linterRegistry.addLinter(linter)
      linter.deactivated = true
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editor}).then ->
          expect(called).toBe(0)

    it 'only sets messages of active editors', ->
      called = 0
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        scope: 'file'
        lint: ->
      }
      linterRegistry.onDidUpdateMessages ->
        called++
      linterRegistry.addLinter(linter)
      atom.workspace.destroyActivePaneItem()
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editor}).then ->
          expect(called).toBe(0)

  describe '::onDidUpdateMessages', ->
    it 'is triggered whenever messages change', ->
      editorLinter = new EditorLinter(editor)
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        scope: 'file'
        lint: -> return [{type: 'Error', text: 'Something'}]
      }
      info = undefined
      linterRegistry.addLinter(linter)
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        info = linterInfo
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editor}).then ->
          expect(info).toBeDefined()
          expect(info.messages.length).toBe(1)
