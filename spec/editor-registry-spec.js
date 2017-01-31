/* @flow */

import { it, beforeEach } from 'jasmine-fix'
import EditorRegistry from '../lib/editor-registry'

describe('EditorRegistry', function() {
  let editorRegistry

  beforeEach(async function() {
    await atom.workspace.open(__filename)
    editorRegistry = new EditorRegistry()
  })
  afterEach(function() {
    atom.workspace.destroyActivePane()
    editorRegistry.dispose()
  })

  describe('::constructor', function() {
    it('is a saint', function() {
      expect(function() {
        return new EditorRegistry()
      }).not.toThrow()
    })
  })

  describe('::activate && ::createFromTextEditor', function() {
    it('adds current open editors to registry', function() {
      expect(editorRegistry.editorLinters.size).toBe(0)
      editorRegistry.activate()
      expect(editorRegistry.editorLinters.size).toBe(1)
    })
    it('adds editors as they are opened', async function() {
      expect(editorRegistry.editorLinters.size).toBe(0)
      editorRegistry.activate()
      expect(editorRegistry.editorLinters.size).toBe(1)
      await atom.workspace.open()
      expect(editorRegistry.editorLinters.size).toBe(2)
    })
    it('removes the editor as it is closed', async function() {
      expect(editorRegistry.editorLinters.size).toBe(0)
      editorRegistry.activate()
      expect(editorRegistry.editorLinters.size).toBe(1)
      await atom.workspace.open()
      expect(editorRegistry.editorLinters.size).toBe(2)
      atom.workspace.destroyActivePaneItem()
      expect(editorRegistry.editorLinters.size).toBe(1)
      atom.workspace.destroyActivePane()
      expect(editorRegistry.editorLinters.size).toBe(0)
    })
    it('does not lint instantly if lintOnOpen is off', async function() {
      editorRegistry.activate()
      atom.config.set('linter.lintOnOpen', false)
      let lintCalls = 0
      editorRegistry.observe(function(editorLinter) {
        editorLinter.onShouldLint(() => ++lintCalls)
      })
      expect(lintCalls).toBe(0)
      await atom.workspace.open()
      expect(lintCalls).toBe(0)
    })
    it('invokes lint instantly if lintOnOpen is on', async function() {
      editorRegistry.activate()
      atom.config.set('linter.lintOnOpen', true)
      let lintCalls = 0
      editorRegistry.observe(function(editorLinter) {
        editorLinter.onShouldLint(() => ++lintCalls)
      })
      expect(lintCalls).toBe(0)
      await atom.workspace.open()
      expect(lintCalls).toBe(1)
    })
  })
  describe('::observe', function() {
    it('calls with current editors and updates as new are opened', async function() {
      let timesCalled = 0
      editorRegistry.observe(function() {
        timesCalled++
      })
      expect(timesCalled).toBe(0)
      editorRegistry.activate()
      expect(timesCalled).toBe(1)
      await atom.workspace.open()
      expect(timesCalled).toBe(2)
    })
  })
  describe('::dispose', function() {
    it('disposes all the editors on dispose', async function() {
      let timesDisposed = 0
      editorRegistry.observe(function(editorLinter) {
        editorLinter.onDidDestroy(function() {
          timesDisposed++
        })
      })
      expect(timesDisposed).toBe(0)
      editorRegistry.activate()
      expect(timesDisposed).toBe(0)
      atom.workspace.destroyActivePaneItem()
      expect(timesDisposed).toBe(1)
      await atom.workspace.open()
      expect(timesDisposed).toBe(1)
      atom.workspace.destroyActivePaneItem()
      expect(timesDisposed).toBe(2)
      await atom.workspace.open()
      await atom.workspace.open()
      editorRegistry.dispose()
      expect(timesDisposed).toBe(4)
    })
  })
})
