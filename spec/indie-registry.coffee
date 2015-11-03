describe 'IndieRegistry', ->
  IndieRegistry = require('../lib/indie-registry')
  indieRegistry = null

  beforeEach ->
    indieRegistry?.dispose()
    indieRegistry = new IndieRegistry()

  describe 'register', ->
    it 'validates the args', ->
      expect ->
        indieRegistry.register({name: 2})
      .toThrow()
      indieRegistry.register({})
      indieRegistry.register({name: 'wow'})

  describe 'all of it', ->
    it 'works', ->
      indie = indieRegistry.register({name: 'Wow'})
      expect(indieRegistry.has(indie)).toBe(false)
      expect(indieRegistry.has(0)).toBe(false)

      listener = jasmine.createSpy('linter.indie.messaging')
      observeListener = jasmine.createSpy('linter.indie.observe')
      messages = [{}]
      indieRegistry.onDidUpdateMessages(listener)
      indieRegistry.observe(observeListener)
      indie.setMessages(messages)
      expect(observeListener).toHaveBeenCalled()
      expect(observeListener).toHaveBeenCalledWith(indie)
      expect(listener).toHaveBeenCalled()
      expect(listener.mostRecentCall.args[0].linter.toBe(indie))
      expect(listener.mostRecentCall.args[0].messages.toBe(messages))
      indie.dispose()
      expect(indieRegistry.has(indie)).toBe(false)
