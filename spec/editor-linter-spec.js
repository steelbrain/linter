'use babel'

import { Disposable } from 'atom'
import { it, beforeEach } from 'jasmine-fix'
import EditorLinter from '../dist/editor-linter'

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

        const promise = new Promise(resolve => {
          editorLinter.onShouldLint(() => {
            timesTriggered++
            // Dispose of the current registration as it is finished
            editorLinter.dispose()
            resolve()
          })
        })
        // Trigger a (async) save
        textEditor.save()
        return promise
      }
      expect(timesTriggered).toBe(0)
      await waitForShouldLint()
      await waitForShouldLint()
      expect(timesTriggered).toBe(2)
    })
    it('is triggered on reload', async function() {
      let timesTriggered = 0
      function waitForShouldLint() {
        // Register on the textEditor
        const editorLinter = new EditorLinter(textEditor)

        const promise = new Promise(resolve => {
          editorLinter.onShouldLint(() => {
            timesTriggered++
            // Dispose of the current registration as it is finished
            editorLinter.dispose()
            resolve()
          })
        })
        // Trigger a (async) save
        textEditor.getBuffer().reload()
        return promise
      }
      expect(timesTriggered).toBe(0)
      await waitForShouldLint()
      await waitForShouldLint()
      expect(timesTriggered).toBe(2)
    })
  })
})


describe('EditorLinter.subscriptiveObserve', function() {
  let editorLinter, textEditor

  beforeEach(async function() {
    await atom.workspace.open(`${__dirname}/fixtures/file.txt`)
    textEditor = atom.workspace.getActiveTextEditor()
    editorLinter = new EditorLinter(textEditor)
  })
  afterEach(function() {
    atom.workspace.destroyActivePaneItem()
  })

  it('activates synchronously', function() {
    let activated = false
    editorLinter.subscriptiveObserve(
      {
        observe(eventName, callback) {
          activated = true
          expect(eventName).toBe('someEvent')
          expect(typeof callback).toBe('function')
        },
      },
      'someEvent',
      function() {},
    )
    expect(activated).toBe(true)
  })
  it('clears last subscription when value changes', function() {
    let disposed = 0
    let activated = false
    editorLinter.subscriptiveObserve(
      {
        observe(eventName, callback) {
          activated = true
          expect(disposed).toBe(0)
          callback()
          expect(disposed).toBe(0)
          callback()
          expect(disposed).toBe(1)
          callback()
          expect(disposed).toBe(2)
        },
      },
      'someEvent',
      function() {
        return new Disposable(function() {
          disposed++
        })
      },
    )
    expect(activated).toBe(true)
  })
  it('clears both subscriptions at the end', function() {
    let disposed = 0
    let observeDisposed = 0
    let activated = false
    const subscription = editorLinter.subscriptiveObserve(
      {
        observe(eventName, callback) {
          activated = true
          expect(disposed).toBe(0)
          callback()
          expect(disposed).toBe(0)
          return new Disposable(function() {
            observeDisposed++
          })
        },
      },
      'someEvent',
      function() {
        return new Disposable(function() {
          disposed++
        })
      },
    )
    expect(activated).toBe(true)
    subscription.dispose()
    expect(disposed).toBe(1)
    expect(observeDisposed).toBe(1)
  })
})
