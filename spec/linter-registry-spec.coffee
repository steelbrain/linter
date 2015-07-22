describe 'linter-registry', ->
  LinterRegistry = require('../lib/linter-registry')
  EditorLinter = require('../lib/editor-linter')
  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt')

  describe '::construct', ->
    it 'expects no arguments', ->
      linterRegistry = new LinterRegistry
      expect(true).toBe(true)
      linterRegistry.deactivate()

  describe '::addLinter', ->
    it 'adds error notification if linter is invalid', ->
      linterRegistry = new LinterRegistry
      linterRegistry.addLinter({})
      linterRegistry.deactivate()
      expect(atom.notifications.getNotifications().length).toBe(1)
    it 'pushes linter into registry when valid', ->
      linter = {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'file', lint: -> }
      linterRegistry = new LinterRegistry
      linterRegistry.addLinter(linter)
      expect(linterRegistry.linters.length).toBe(1)
      linterRegistry.deactivate()

  describe '::hasLinter', ->
    it 'returns true if present', ->
      linter = {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'file', lint: -> }
      linterRegistry = new LinterRegistry
      linterRegistry.addLinter(linter)
      expect(linterRegistry.hasLinter(linter)).toBe(true)
      linterRegistry.deactivate()
    it 'returns false if not', ->
      linter = {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'file', lint: -> }
      linterRegistry = new LinterRegistry
      expect(linterRegistry.hasLinter(linter)).toBe(false)
      linterRegistry.deactivate()

  describe '::deleteLinter', ->
    it 'deletes the linter from registry', ->
      linter = {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'file', lint: -> }
      linterRegistry = new LinterRegistry
      linterRegistry.addLinter(linter)
      expect(linterRegistry.hasLinter(linter)).toBe(true)
      linterRegistry.deleteLinter(linter)
      expect(linterRegistry.hasLinter(linter)).toBe(false)
      linterRegistry.deactivate()

  describe '::lint', ->
    it "doesn't lint if textEditor isn't active one", ->
      linterRegistry = new LinterRegistry
      editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
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
          expect(linterRegistry.lint({onChange: false, editorLinter})).toBeUndefined()
          linterRegistry.deactivate()
    it "doesn't lint if textEditor doesn't have a path", ->
      linterRegistry = new LinterRegistry
      editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        modifiesBuffer: false
        scope: 'file'
        lint: ->
      }
      linterRegistry.addLinter(linter)
      waitsForPromise ->
        atom.workspace.open('someNonExistingFile.txt').then ->
          expect(linterRegistry.lint({onChange: false, editorLinter})).toBeUndefined()
          linterRegistry.deactivate()
    it 'disallows two co-current lints of same type', ->
      linterRegistry = new LinterRegistry
      editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        modifiesBuffer: false
        scope: 'file'
        lint: ->
      }
      linterRegistry.addLinter(linter)
      expect(linterRegistry.lint({onChange: false, editorLinter})).toBeDefined()
      expect(linterRegistry.lint({onChange: false, editorLinter})).toBeUndefined()
      linterRegistry.deactivate()

    describe 'buffer modifying linter', ->
      it 'triggers before other linters', ->
        last = null
        normalLinter = {
          grammarScopes: ['*']
          lintOnFly: false
          modifiesBuffer: false
          scope: 'file'
          lint: -> last = 'normal'
        }
        bufferModifying = {
          grammarScopes: ['*']
          lintOnFly: false
          modifiesBuffer: true
          scope: 'file'
          lint: -> last = 'bufferModifying'
        }
        linterRegistry = new LinterRegistry
        editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
        linterRegistry.addLinter(normalLinter)
        linterRegistry.addLinter(bufferModifying)
        waitsForPromise ->
          linterRegistry.lint({onChange: false, editorLinter}).then ->
            expect(last).toBe('normal')
            linterRegistry.deactivate()
      it 'runs in sequence', ->
        order = []
        first = {
          grammarScopes: ['*']
          lintOnFly: false
          modifiesBuffer: true
          scope: 'file'
          lint: -> order.push('first')
        }
        second = {
          grammarScopes: ['*']
          lintOnFly: false
          modifiesBuffer: true
          scope: 'file'
          lint: -> order.push('second')
        }
        third = {
          grammarScopes: ['*']
          lintOnFly: false
          modifiesBuffer: true
          scope: 'file'
          lint: -> order.push('third')
        }
        linterRegistry = new LinterRegistry
        editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
        linterRegistry.addLinter(first)
        linterRegistry.addLinter(second)
        linterRegistry.addLinter(third)
        waitsForPromise ->
          linterRegistry.lint({onChange: false, editorLinter}).then ->
            expect(order[0]).toBe('first')
            expect(order[1]).toBe('second')
            expect(order[2]).toBe('third')
            linterRegistry.deactivate()

  describe '::onDidUpdateMessages', ->
    it 'is triggered whenever messages change', ->
      linterRegistry = new LinterRegistry
      editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
      linter = {
        grammarScopes: ['*']
        lintOnFly: false
        modifiesBuffer: false
        scope: 'file'
        lint: -> return [{type: "Error", text: "Something"}]
      }
      info = undefined
      linterRegistry.addLinter(linter)
      linterRegistry.onDidUpdateMessages (linterInfo) ->
        info = linterInfo
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          expect(info).toBeDefined()
          expect(info.messages.length).toBe(1)
          linterRegistry.deactivate()
