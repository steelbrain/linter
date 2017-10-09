'use babel'

import * as fs from 'fs'
import rimraf from 'rimraf'
import { tmpdir } from 'os'
import * as path from 'path'
// eslint-disable-next-line no-unused-vars
import { it, fit, wait, beforeEach, afterEach } from 'jasmine-fix'
import EditorLinter from '../lib/editor-linter'

/**
 * Async helper to copy a file from one place to another on the filesystem.
 * @param  {string} fileToCopyPath  Path of the file to be copied
 * @param  {string} destinationDir  Directory to paste the file into
 * @return {string}                 Full path of the file in copy destination
 */
function copyFileToDir(fileToCopyPath, destinationDir) {
  return new Promise((resolve) => {
    const destinationPath = path.join(destinationDir, path.basename(fileToCopyPath))
    const ws = fs.createWriteStream(destinationPath)
    ws.on('close', () => resolve(destinationPath))
    fs.createReadStream(fileToCopyPath).pipe(ws)
  })
}

/**
 * Utility helper to copy a file into the OS temp directory.
 *
 * @param  {string} fileToCopyPath  Path of the file to be copied
 * @return {string}                 Full path of the file in copy destination
 */
function copyFileToTempDir(fileToCopyPath) {
  return new Promise((resolve, reject) => {
    fs.mkdtemp(tmpdir() + path.sep, (err, tempFixtureDir) => {
      if (err) {
        reject(err)
      }
      resolve(copyFileToDir(fileToCopyPath, tempFixtureDir))
    })
  })
}

/**
 * Asynchronously append "foobar\n" to the given file
 * @param  {string} filePath Path of the file to append to
 * @return {undefined}
 */
function modifyFile(filePath) {
  return new Promise((resolve, reject) => {
    fs.appendFile(filePath, 'foobar\n', (err) => {
      if (err) {
        reject(err)
      }
      resolve()
    })
  })
}

describe('EditorLinter', function() {
  let textEditor

  beforeEach(async function() {
    await atom.workspace.open(`${__dirname}/fixtures/file.txt`)
    textEditor = atom.workspace.getActiveTextEditor()
  })
  afterEach(function() {
    atom.workspace.destroyActivePaneItem()
  })

  it('cries when constructor argument is not a text editor', function() {
    expect(function() {
      return new EditorLinter()
    }).toThrow('EditorLinter expects a valid TextEditor')
    expect(function() {
      return new EditorLinter(1)
    }).toThrow('EditorLinter expects a valid TextEditor')
    expect(function() {
      return new EditorLinter({})
    }).toThrow('EditorLinter expects a valid TextEditor')
    expect(function() {
      return new EditorLinter('')
    }).toThrow('EditorLinter expects a valid TextEditor')
  })

  describe('onDidDestroy', function() {
    it('is called when text editor is destroyed', function() {
      let triggered = false
      const editor = new EditorLinter(textEditor)
      editor.onDidDestroy(function() {
        triggered = true
      })
      expect(triggered).toBe(false)
      textEditor.destroy()
      expect(triggered).toBe(true)
    })
  })

  describe('onShouldLint', function() {
    let timesTriggered
    let editor

    function waitForShouldLint() {
      // Register on the textEditor
      const editorLinter = new EditorLinter(editor)
      return new Promise((resolve) => {
        editorLinter.onShouldLint(() => {
          timesTriggered++
          // Dispose of the current registration as it is finished
          editorLinter.dispose()
          resolve()
        })
      })
    }

    beforeEach(() => {
      timesTriggered = 0
    })

    it('is triggered on save', async function() {
      editor = textEditor
      expect(timesTriggered).toBe(0)
      // Trigger an async save
      textEditor.save()
      await waitForShouldLint()
      textEditor.save()
      await waitForShouldLint()
      expect(timesTriggered).toBe(2)
    })

    it('is triggered on reload', async function() {
      const tempPath = await copyFileToTempDir(path.join(__dirname, 'fixtures', 'file.txt'))
      const tempDir = path.dirname(tempPath)
      editor = await atom.workspace.open(tempPath)

      expect(timesTriggered).toBe(0)
      modifyFile(tempPath)
      await waitForShouldLint()
      modifyFile(tempPath)
      await waitForShouldLint()
      expect(timesTriggered).toBe(2)

      rimraf.sync(tempDir)
    }, { timeout: 1500 })
  })
})
