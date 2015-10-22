describe 'Linter Config', ->
  linter = null
  {getLinter, getMessage} = require('./common')
  CP = require('child_process')
  FS = require('fs')
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
      repoPath = "/tmp/linter_git_repo"
      CP.execSync("rm -rf #{repoPath}")
      CP.execSync("mkdir #{repoPath}")
      CP.execSync("cd #{repoPath}; git init")
      FS.writeFileSync("#{repoPath}/.gitignore", "/test.js\n")
      FS.writeFileSync("#{repoPath}/test.js", "'use strict'\n")
      atom.config.set('linter.ignoreVCSIgnoredFiles', true)
      atom.project.addPath(repoPath)
      linterProvider = getLinter()
      spyOn(linterProvider, 'lint')
      linter.addLinter(linterProvider)

      waitsForPromise ->
        atom.workspace.open("#{repoPath}/test.js").then ->
          editor = atom.workspace.getActiveTextEditor()
          editor.insertText("a")
          editor.save()
          expect(linterProvider.lint).not.toHaveBeenCalled()
          atom.config.set('linter.ignoreVCSIgnoredFiles', false)
          editor.insertText("a")
          editor.save()
          expect(linterProvider.lint).toHaveBeenCalled()
          CP.execSync("rm -rf #{repoPath}")
