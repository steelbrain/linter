import type { Disposable, TextEditor } from 'atom';
import EditorLinter from './editor-linter';
export default class EditorRegistry {
    private emitter;
    private lintOnOpen;
    private subscriptions;
    private editorLinters;
    constructor();
    activate(): void;
    get(textEditor: TextEditor): EditorLinter | null | undefined;
    createFromTextEditor(textEditor: TextEditor): EditorLinter;
    hasSibling(editorLinter: EditorLinter): boolean;
    observe(callback: (editorLinter: EditorLinter) => void): Disposable;
    dispose(): void;
}
