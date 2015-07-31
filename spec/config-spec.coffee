describe 'Linter Config', ->
  linter = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  getLinter = ->
    return {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'project', lint: -> }
  getMessage = (type) ->
    return {type, text: "Some Message"}
  nextAnimationFrame = ->
    return new Promise (resolve) -> requestAnimationFrame(resolve)

  describe 'ignoredMessageTypes', ->
    it 'ignores certain types of messages', ->
      linterProvider = getLinter()
      expect(linter.messages.publicMessages.length).toBe(0)
      linter.messages.set({linter: linterProvider, messages: [getMessage('Error'), getMessage('Warning')]})
      waitsForPromise ->
        nextAnimationFrame().then( ->
          expect(linter.messages.publicMessages.length).toBe(2)
          atom.config.set('linter.ignoredMessageTypes', ['Error'])
          linter.messages.set({linter: linterProvider, messages: [getMessage('Error'), getMessage('Warning')]})
          return nextAnimationFrame()
        ).then ->
          expect(linter.messages.publicMessages.length).toBe(1)

