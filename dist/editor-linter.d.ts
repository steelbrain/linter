import { Disposable } from 'atom';
import type { TextEditor } from 'atom';
export default class EditorLinter {
    private editor;
    private emitter;
    private subscriptions;
    constructor(editor: TextEditor);
    getEditor(): TextEditor;
    lint(onChange?: boolean): void;
    onShouldLint(callback: (...args: Array<any>) => any): Disposable;
    onDidDestroy(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
    subscriptiveObserve(object: Record<string, any>, eventName: string, callback: (...args: Array<any>) => any): Disposable;
}
