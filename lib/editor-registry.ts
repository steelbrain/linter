import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable, TextEditor } from 'atom'
import EditorLinter from './editor-linter'

export default class EditorRegistry {
  private emitter: Emitter = new Emitter()
  private lintOnOpen: boolean = true
  private subscriptions: CompositeDisposable = new CompositeDisposable()
  private editorLinters: Map<TextEditor, EditorLinter> = new Map()

  constructor() {
    this.subscriptions.add(
      this.emitter,
      atom.config.observe('linter.lintOnOpen', lintOnOpen => {
        this.lintOnOpen = lintOnOpen
      }),
    )
  }
  activate() {
    this.subscriptions.add(
      atom.workspace.observeTextEditors(textEditor => {
        this.createFromTextEditor(textEditor)
      }),
    )
  }
  get(textEditor: TextEditor): EditorLinter | null | undefined {
    return this.editorLinters.get(textEditor)
  }
  createFromTextEditor(textEditor: TextEditor): EditorLinter {
    let editorLinter = this.editorLinters.get(textEditor)
    if (editorLinter) {
      return editorLinter
    }
    editorLinter = new EditorLinter(textEditor)
    editorLinter.onDidDestroy(() => {
      this.editorLinters.delete(textEditor)
    })
    this.editorLinters.set(textEditor, editorLinter)
    this.emitter.emit('observe', editorLinter)
    if (this.lintOnOpen) {
      editorLinter.lint()
    }
    return editorLinter
  }
  hasSibling(editorLinter: EditorLinter): boolean {
    const buffer = editorLinter.getEditor().getBuffer()

    return Array.from(this.editorLinters.keys()).some(item => item.getBuffer() === buffer)
  }
  observe(callback: (editorLinter: EditorLinter) => void): Disposable {
    this.editorLinters.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  dispose() {
    for (const entry of this.editorLinters.values()) {
      entry.dispose()
    }
    this.subscriptions.dispose()
  }
}
