import type { Disposable } from 'atom';
import type { Linter, UI } from './types';
import type IndieDelegate from './indie-delegate';
export declare class Commands {
    private emitter;
    private subscriptions;
    constructor();
    lint(): void;
    debug(): void;
    enableLinter(): void;
    disableLinter(): void;
    toggleActiveEditor(): void;
    showDebug(...args: Parameters<typeof showDebug>): void;
    onShouldLint(callback: (...args: Array<any>) => any): Disposable;
    onShouldDebug(callback: (...args: Array<any>) => any): Disposable;
    onShouldToggleActiveEditor(callback: (...args: Array<any>) => any): Disposable;
    onShouldToggleLinter(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
}
export declare function showDebug(standardLinters: Array<Linter>, indieLinters: Array<IndieDelegate>, uiProviders: Array<UI>): Promise<void>;
