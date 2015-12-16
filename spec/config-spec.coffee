describe 'Linter Config', ->
  linter = null
  {getLinter, getMessage} = require('./common')
  Path = require('path')
  FS = require('fs')
  Helpers = require('../lib/helpers')

  TempDir = require('os').tmpdir()

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
      filePath = Path.join(TempDir, 'linter_spec_ignored_vcs.min.js')
      FS.writeFileSync(filePath, 'Hello Dolly')

      atom.config.set('linter.ignoreVCSIgnoredFiles', true)
      linterProvider = getLinter()
      spyOn(linterProvider, 'lint')
      spyOn(Helpers, 'isPathIgnored').andCallFake( -> true)

      linter.addLinter(linterProvider)

      waitsForPromise ->
        atom.workspace.open(filePath).then ->
          linter.commands.lint()
          expect(linterProvider.lint).not.toHaveBeenCalled()
          atom.config.set('linter.ignoreVCSIgnoredFiles', false)
          linter.commands.lint()
          expect(linterProvider.lint).toHaveBeenCalled()
          FS.unlinkSync(filePath)

  describe 'ignoreMatchedFiles', ->
    it 'ignores the file if it matches pattern', ->
      filePath = Path.join(TempDir, 'linter_spec_ignored_match.min.js')
      FS.writeFileSync(filePath, 'Hello Dolly')

      atom.config.set('linter.ignoreMatchedFiles', '{\,/}**{\,/}*.min.{js,css}')
      linterProvider = getLinter()
      spyOn(linterProvider, 'lint')

      linter.addLinter(linterProvider)

      waitsForPromise ->
        atom.workspace.open(filePath).then ->
          linter.commands.lint()
          expect(linterProvider.lint).not.toHaveBeenCalled()
          atom.config.set('linter.ignoreMatchedFiles', '{\,/}**{\,/}*.min.css')
          linter.commands.lint()
          expect(linterProvider.lint).toHaveBeenCalled()
          FS.unlinkSync(filePath)
