import type { TextEditor, Disposable } from 'atom';
import type { Linter } from './types';
export default class LinterRegistry {
    private emitter;
    private linters;
    private lintOnChange;
    private ignoreVCS;
    private ignoreGlob;
    private lintPreviewTabs;
    private subscriptions;
    private disabledProviders;
    private activeNotifications;
    constructor();
    hasLinter(linter: Linter): boolean;
    addLinter(linter: Linter): void;
    getProviders(): Array<Linter>;
    deleteLinter(linter: Linter): void;
    lint({ onChange, editor }: {
        onChange: boolean;
        editor: TextEditor;
    }): Promise<boolean>;
    onDidUpdateMessages(callback: (...args: Array<any>) => any): Disposable;
    onDidBeginLinting(callback: (...args: Array<any>) => any): Disposable;
    onDidFinishLinting(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
}
