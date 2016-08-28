'use babel'

import { it, wait, beforeEach } from 'jasmine-fix'
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
      const editor = new EditorLinter(textEditor)
      editor.onShouldLint(function() {
        timesTriggered++
      })
      textEditor.save()
      textEditor.save()
      textEditor.save()
      textEditor.save()
      expect(timesTriggered).toBe(0)
      await wait(10)
      expect(timesTriggered).toBe(1)
      textEditor.save()
      textEditor.save()
      textEditor.save()
      textEditor.save()
      expect(timesTriggered).toBe(1)
      await wait(10)
      expect(timesTriggered).toBe(2)
    })
  })
})
