import { Emitter, CompositeDisposable } from 'atom';
import type { Disposable, TextEditor } from 'atom';
import EditorLinter from './editor-linter';
export default class EditorRegistry {
    emitter: Emitter;
    lintOnOpen: boolean;
    subscriptions: CompositeDisposable;
    editorLinters: Map<TextEditor, EditorLinter>;
    constructor();
    activate(): void;
    get(textEditor: TextEditor): EditorLinter | null | undefined;
    createFromTextEditor(textEditor: TextEditor): EditorLinter;
    hasSibling(editorLinter: EditorLinter): boolean;
    observe(callback: (editorLinter: EditorLinter) => void): Disposable;
    dispose(): void;
}
