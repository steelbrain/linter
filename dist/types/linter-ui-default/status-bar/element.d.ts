import { CompositeDisposable, Emitter } from 'atom';
import type { Disposable } from 'atom';
export default class Element {
    item: HTMLElement;
    itemErrors: HTMLElement;
    itemWarnings: HTMLElement;
    itemInfos: HTMLElement;
    emitter: Emitter<{}, {
        click: 'error' | 'warning' | 'info';
    }>;
    subscriptions: CompositeDisposable;
    constructor();
    setVisibility(prefix: string, visibility: boolean): void;
    update(countErrors: number, countWarnings: number, countInfos: number): void;
    onDidClick(callback: (type: 'error' | 'warning' | 'info') => void): Disposable;
    dispose(): void;
}
