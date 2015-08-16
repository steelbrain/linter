describe 'editor-registry', ->
  EditorRegistry = require('../lib/editor-registry')
  editorRegistry = null
  beforeEach ->
    waitsForPromise ->
      atom.workspace.destroyActivePaneItem()
      atom.workspace.open('test.txt')
    editorRegistry?.dispose()
    editorRegistry = new EditorRegistry

  describe '::create', ->
    it 'cries when invalid TextEditor was provided', ->
      expect ->
        editorRegistry.create()
      .toThrow("Given editor isn't really an editor")
      expect ->
        editorRegistry.create(5)
      .toThrow("Given editor isn't really an editor")
    it "adds TextEditor to it's registry", ->
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      expect(editorRegistry.editorLinters.size).toBe(1)
    it 'automatically clears the TextEditor from registry when destroyed', ->
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      atom.workspace.destroyActivePaneItem()
      expect(editorRegistry.editorLinters.size).toBe(0)

  describe '::forEach', ->
    it 'calls the callback once per editorLinter', ->
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      timesCalled = 0
      editorRegistry.forEach -> ++timesCalled
      editorRegistry.forEach -> ++timesCalled
      expect(timesCalled).toBe(2)

  describe '::ofTextEditor', ->
    it 'returns undefined when invalid key is provided', ->
      expect(editorRegistry.ofTextEditor(null)).toBeUndefined()
      expect(editorRegistry.ofTextEditor(1)).toBeUndefined()
      expect(editorRegistry.ofTextEditor(5)).toBeUndefined()
      expect(editorRegistry.ofTextEditor("asd")).toBeUndefined()
    it 'returns editorLinter when valid key is provided', ->
      activeEditor = atom.workspace.getActiveTextEditor()
      editorRegistry.create(activeEditor)
      expect(editorRegistry.ofTextEditor(activeEditor)).toBeDefined()

  describe '::observe', ->
    it 'calls with the current editorLinters', ->
      timesCalled = 0
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      editorRegistry.observe -> ++timesCalled
      expect(timesCalled).toBe(1)
    it 'calls in the future with new editorLinters', ->
      timesCalled = 0
      editorRegistry.observe -> ++timesCalled
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      waitsForPromise ->
        atom.workspace.open('someNonExistingFile').then ->
          editorRegistry.create(atom.workspace.getActiveTextEditor())
          expect(timesCalled).toBe(2)

  describe '::ofActiveTextEditor', ->
    it 'returns undefined if active pane is not a text editor', ->
      expect(editorRegistry.ofActiveTextEditor()).toBeUndefined()
    it 'returns editorLinter when active pane is a text editor', ->
      editorRegistry.create(atom.workspace.getActiveTextEditor())
      expect(editorRegistry.ofActiveTextEditor()).toBeDefined()
