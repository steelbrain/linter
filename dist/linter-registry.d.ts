import { Emitter, CompositeDisposable } from 'atom';
import type { TextEditor, Disposable, Notification } from 'atom';
import type { Linter } from './types';
declare class LinterRegistry {
    emitter: Emitter;
    linters: Set<Linter>;
    lintOnChange: boolean;
    ignoreVCS: boolean;
    ignoreGlob: string;
    lintPreviewTabs: boolean;
    subscriptions: CompositeDisposable;
    disabledProviders: Array<string>;
    activeNotifications: Set<Notification>;
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
export default LinterRegistry;
