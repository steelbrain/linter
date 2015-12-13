describe 'Linter Indie API', ->

  linter = null
  {wait} = require('./common')
  Remote = require('remote')

  beforeEach ->
    global.setTimeout = Remote.getGlobal('setTimeout')
    global.setInterval = Remote.getGlobal('setInterval')
    waitsForPromise ->
      atom.packages.activate('linter').then ->
        linter = atom.packages.getActivePackage(linter)

  describe 'it works', ->
    indieLinter = linter.indieLinter.register({name: 'Wow'})
    indieLinter.setMessages([{type: 'Error', text: 'Hey!'}])
    waitsForPromise ->
      wait(100).then ->
        expect(linter.messages.publicMessages.length).toBe(1)
        indieLinter.deleteMessages()
        wait(100)
      .then ->
        expect(linter.messages.publicMessages.length).toBe(0)
