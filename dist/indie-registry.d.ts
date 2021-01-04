import { Emitter, CompositeDisposable } from 'atom';
import type { Disposable } from 'atom';
import IndieDelegate from './indie-delegate';
import type { Indie } from './types';
declare class IndieRegistry {
    emitter: Emitter;
    delegates: Set<IndieDelegate>;
    subscriptions: CompositeDisposable;
    constructor();
    register(config: Indie, version: 2): IndieDelegate;
    getProviders(): Array<IndieDelegate>;
    observe(callback: (...args: Array<any>) => any): Disposable;
    onDidUpdate(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
}
export default IndieRegistry;
