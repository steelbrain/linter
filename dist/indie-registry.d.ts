import type { Disposable } from 'atom';
import IndieDelegate from './indie-delegate';
import type { Indie } from './types';
export default class IndieRegistry {
    private emitter;
    private delegates;
    private subscriptions;
    constructor();
    register(config: Indie, version: 2): IndieDelegate;
    getProviders(): Array<IndieDelegate>;
    observe(callback: (...args: Array<any>) => any): Disposable;
    onDidUpdate(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
}
