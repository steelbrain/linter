describe 'editor-registry', ->
  EditorRegistry = require('../lib/editor-registry')
  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt')
  describe '::constructor', ->
    it 'expects no arguments', ->
      editorRegistry = new EditorRegistry
      editorRegistry.deactivate()
  describe '::create', ->
    it 'cries when invalid TextEditor was provided', ->
      editorRegistry = new EditorRegistry
      expect ->
        editorRegistry.create()
      .toThrow("Given editor isn't really an editor")
      expect ->
        editorRegistry.create(5)
      .toThrow("Given editor isn't really an editor")
      editorRegistry.deactivate()
    it "adds TextEditor to it's registry", ->
      editorRegistry = new EditorRegistry
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      expect(editorRegistry.editorLinters.size).toBe(1)
      editorRegistry.deactivate()
    it 'automatically clears the TextEditor from registry when destroyed', ->
      editorRegistry = new EditorRegistry
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      atom.workspace.destroyActivePaneItem()
      expect(editorRegistry.editorLinters.size).toBe(0)
      editorRegistry.deactivate()
  describe '::ofTextEditor', ->
    it 'returns undefined when invalid key is provided', ->
      editorRegistry = new EditorRegistry
      expect(editorRegistry.ofTextEditor(null)).toBeUndefined()
      expect(editorRegistry.ofTextEditor(1)).toBeUndefined()
      expect(editorRegistry.ofTextEditor(5)).toBeUndefined()
      expect(editorRegistry.ofTextEditor("asd")).toBeUndefined()
      editorRegistry.deactivate()
    it 'returns editorLinter when valid key is provided', ->
      activeEditor = atom.workspace.getActiveTextEditor()
      editorRegistry = new EditorRegistry
      editorRegistry.create(activeEditor)
      expect(editorRegistry.ofTextEditor(activeEditor)).toBeDefined()
      editorRegistry.deactivate()
  describe '::ofActiveTextEditor', ->
    it 'returns undefined if active pane is not a text editor', ->
      editorRegistry = new EditorRegistry
      expect(editorRegistry.ofActiveTextEditor()).toBeUndefined()
      editorRegistry.deactivate()
    it 'returns editorLinter when active pane is a text editor', ->
      editorRegistry = new EditorRegistry
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      expect(editorRegistry.ofActiveTextEditor()).toBeDefined()
      editorRegistry.deactivate()
