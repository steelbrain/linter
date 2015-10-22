describe 'Linter Config', ->
  linter = null
  {getLinter, getMessage} = require('./common')
  CP = require('child_process')
  FS = require('fs')
  Helpers = require('../lib/helpers')
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  describe 'ignoredMessageTypes', ->
    it 'ignores certain types of messages', ->
      linterProvider = getLinter()
      expect(linter.messages.publicMessages.length).toBe(0)
      linter.messages.set({linter: linterProvider, messages: [getMessage('Error'), getMessage('Warning')]})
      linter.messages.updatePublic()
      expect(linter.messages.publicMessages.length).toBe(2)
      atom.config.set('linter.ignoredMessageTypes', ['Error'])
      linter.messages.set({linter: linterProvider, messages: [getMessage('Error'), getMessage('Warning')]})
      linter.messages.updatePublic()
      expect(linter.messages.publicMessages.length).toBe(1)

  describe 'statusIconScope', ->
    it 'only shows messages of the current scope', ->
      linterProvider = getLinter()
      expect(linter.views.bottomContainer.status.count).toBe(0)
      linter.messages.set({linter: linterProvider, messages: [getMessage('Error', '/tmp/test.coffee')]})
      linter.messages.updatePublic()
      expect(linter.views.bottomContainer.status.count).toBe(1)
      atom.config.set('linter.statusIconScope', 'File')
      expect(linter.views.bottomContainer.status.count).toBe(0)
      atom.config.set('linter.statusIconScope', 'Project')
      expect(linter.views.bottomContainer.status.count).toBe(1)
  describe 'ignoreVCSIgnoredFiles', ->
    it 'ignores the file if its ignored by the VCS', ->
      filePath = "/tmp/linter_test_file"
      FS.writeFileSync(filePath, "'use strict'\n")

      atom.config.set('linter.ignoreVCSIgnoredFiles', true)
      linterProvider = getLinter()
      spyOn(linterProvider, 'lint')
      spyOn(Helpers, 'isPathIgnored').andCallFake( -> true)

      linter.addLinter(linterProvider)

      waitsForPromise ->
        atom.workspace.open(filePath).then ->
          editor = atom.workspace.getActiveTextEditor()
          editor.insertText("a")
          editor.save()
          expect(linterProvider.lint).not.toHaveBeenCalled()
          atom.config.set('linter.ignoreVCSIgnoredFiles', false)
          editor.insertText("a")
          editor.save()
          expect(linterProvider.lint).toHaveBeenCalled()
          CP.execSync("rm -f #{filePath}")
