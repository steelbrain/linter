import { CompositeDisposable, Emitter } from 'atom';
import type { Disposable } from 'atom';
export default class TooltipDelegate {
    emitter: Emitter;
    expanded: boolean;
    subscriptions: CompositeDisposable;
    showProviderName?: boolean;
    constructor();
    onShouldUpdate(callback: () => void): Disposable;
    onShouldExpand(callback: () => void): Disposable;
    onShouldCollapse(callback: () => void): Disposable;
    dispose(): void;
}
