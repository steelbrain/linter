import { CompositeDisposable } from 'atom';
import type { LinterMessage } from './types';
export default class Commands {
    messages: Array<LinterMessage>;
    subscriptions: CompositeDisposable;
    constructor();
    applyAllSolutions(): void;
    move(forward: boolean, globally: boolean, severity?: string | null | undefined): void;
    update(messages: Array<LinterMessage>): void;
    dispose(): void;
}
