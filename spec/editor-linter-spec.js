'use babel'

import { it, beforeEach } from 'jasmine-fix'
import EditorLinter from '../lib/editor-linter'

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
    it('is triggered on save', async function() {
      let timesTriggered = 0
      function waitForShouldLint() {
        // Register on the textEditor
        const editorLinter = new EditorLinter(textEditor)
        // Trigger a (async) save
        textEditor.save()
        return new Promise((resolve) => {
          editorLinter.onShouldLint(() => {
            timesTriggered++
            // Dispose of the current registration as it is finished
            editorLinter.dispose()
            resolve()
          })
        })
      }
      expect(timesTriggered).toBe(0)
      await waitForShouldLint()
      await waitForShouldLint()
      expect(timesTriggered).toBe(2)
    })
  })
})
