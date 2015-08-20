describe 'linter-registry', ->
  LinterRegistry = require('../lib/linter-registry')
  EditorLinter = require('../lib/editor-linter')
  linterRegistry = null
  {getLinter, getMessage} = require('./common')

  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('file.txt')
    linterRegistry?.dispose()
    linterRegistry = new LinterRegistry

  describe '::addLinter', ->
    it 'adds error notification if linter is invalid', ->
      linterRegistry.addLinter({})
      expect(atom.notifications.getNotifications().length).toBe(1)
    it 'pushes linter into registry when valid', ->
      linter = getLinter()
      linterRegistry.addLinter(linter)
      expect(linterRegistry.linters.length).toBe(1)
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
    it "doesn't lint if textEditor doesn't have a path", ->
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
    it 'disallows two co-current lints of same type', ->
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

    it 'respects batchUpdateMessages config', ->
      # TODO(steelbrain): This spec doesn't really work. :facepalm:
      remote = require('remote')
      setTimeout = remote.getGlobal('setTimeout')
      setInterval = remote.getGlobal('setInterval')
      lastRun = null

      bufferModifying = {
        grammarScopes: ['*'],
        lintOnFly: false,
        modifiesBuffer: true,
        scope: 'file',
        lint: ->
          expect(lastRun).toBe(null)
          lastRun = 'bufferModifying'
      }
      normalLinter = {
        grammarScopes: ['*'],
        lintOnFly: false,
        modifiesBuffer: false,
        scope: 'file',
        lint: ->
          expect(lastRun).toBe('bufferModifying')
          lastRun = 'normal'
          [getMessage('Error', "#{__dirname}/fixtures/file.txt")]
      }
      lazyLinter = {
        grammarScopes: ['*'],
        lintOnFly: false,
        modifiesBuffer: false,
        scope: 'file',
        lint: ->
          expect(lastRun).toBe('normal')
          lastRun = null
          return new Promise (resolve) ->
            setTimeout( ->
              resolve([getMessage('Error', "#{__dirname}/fixtures/file.txt")])
            , 1000)
      }
      batchUpdateMessages = false # It's false by default
      linterRegistry.addLinter(normalLinter)
      linterRegistry.addLinter(bufferModifying)
      linterRegistry.addLinter(lazyLinter)

      lastTimeNormal = null
      lastTimeBatch = null
      linterRegistry.onDidUpdateMessages ({linter}) ->
        if batchUpdateMessages
          return unless linter is lazyLinter
          unless lastTimeBatch
            return lastTimeBatch = new Date()
          expect((new Date()) - lastTimeBatch >= 1000).toBe(true)
          lastTimeBatch = new Date()
        else
          return unless linter is normalLinter
          unless lastTimeNormal
            return lastTimeNormal = new Date()
          expect((new Date()) - lastTimeNormal < 10).toBe(true)
          lastTimeNormal = new Date()

      editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
      waitsForPromise ->
        linterRegistry.lint({onChange: false, editorLinter}).then ->
          atom.config.set('linter.batchUpdateMessages', (batchUpdateMessages = !batchUpdateMessages))
          linterRegistry.lint({onChange: false, editorLinter})
        .then ->
          expect(lastTimeNormal isnt null).toBe(true)
          expect(lastTimeBatch isnt null).toBe(true)

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
        editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
        linterRegistry.addLinter(normalLinter)
        linterRegistry.addLinter(bufferModifying)
        waitsForPromise ->
          linterRegistry.lint({onChange: false, editorLinter}).then ->
            expect(last).toBe('normal')
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
        editorLinter = new EditorLinter(atom.workspace.getActiveTextEditor())
        linterRegistry.addLinter(first)
        linterRegistry.addLinter(second)
        linterRegistry.addLinter(third)
        waitsForPromise ->
          linterRegistry.lint({onChange: false, editorLinter}).then ->
            expect(order[0]).toBe('first')
            expect(order[1]).toBe('second')
            expect(order[2]).toBe('third')

  describe '::onDidUpdateMessages', ->
    it 'is triggered whenever messages change', ->
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
