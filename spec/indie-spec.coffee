describe 'Indie', ->
  Validate = require('../lib/validate')
  Indie = require('../lib/indie')
  indie = null

  beforeEach ->
    indie?.dispose()
    indie = new Indie({})

  describe 'Validations', ->
    it 'just cares about a name', ->
      linter = {}
      Validate.linter(linter, true)
      expect(linter.name).toBe(null)
      linter.name = 'a'
      Validate.linter(linter, true)
      expect(linter.name).toBe('a')
      linter.name = 2
      expect ->
        Validate.linter(linter, true)
      .toThrow()

  describe 'constructor', ->
    it 'sets a scope for message registry to know', ->
      expect(indie.scope).toBe('project')

  describe '{set, delete}Messages', ->
    it 'notifies the event listeners of the change', ->
      listener = jasmine.createSpy('indie.listener')
      messages = [{}]
      indie.onDidUpdateMessages(listener)
      indie.setMessages(messages)
      expect(listener).toHaveBeenCalled()
      expect(listener.calls.length).toBe(1)
      expect(listener).toHaveBeenCalledWith(messages)
      indie.deleteMessages()
      expect(listener.calls.length).toBe(2)
      expect(listener.mostRecentCall.args[0] instanceof Array)
      expect(listener.mostRecentCall.args[0].length).toBe(0)

  describe 'dispose', ->
    it 'triggers the onDidDestroy event', ->
      listener = jasmine.createSpy('indie.destroy')
      indie.onDidDestroy(listener)
      indie.dispose()
      expect(listener).toHaveBeenCalled()
