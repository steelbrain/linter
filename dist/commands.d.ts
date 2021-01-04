import { CompositeDisposable, Emitter } from 'atom';
import type { Disposable } from 'atom';
import type { Linter, UI } from './types';
import type IndieDelegate from './indie-delegate';
export default class Commands {
    emitter: Emitter;
    subscriptions: CompositeDisposable;
    constructor();
    lint(): void;
    debug(): void;
    enableLinter(): void;
    disableLinter(): void;
    toggleActiveEditor(): void;
    showDebug(standardLinters: Array<Linter>, indieLinters: Array<IndieDelegate>, uiProviders: Array<UI>): void;
    onShouldLint(callback: (...args: Array<any>) => any): Disposable;
    onShouldDebug(callback: (...args: Array<any>) => any): Disposable;
    onShouldToggleActiveEditor(callback: (...args: Array<any>) => any): Disposable;
    onShouldToggleLinter(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
}
