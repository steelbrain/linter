import { CompositeDisposable } from 'atom';
import type { Linter } from './types';
import { BusySignalProvider, BusySignalRegistry } from 'atom-ide-base';
export default class BusySignal {
    provider: BusySignalProvider | null | undefined;
    executing: Set<{
        linter: Linter;
        filePath: string | null | undefined;
    }>;
    providerTitles: Set<string>;
    useBusySignal: boolean;
    subscriptions: CompositeDisposable;
    constructor();
    attach(registry: BusySignalRegistry): void;
    update(): void;
    getExecuting(linter: Linter, filePath: string | null | undefined): {
        linter: Linter;
        filePath: string | null | undefined;
    } | null;
    didBeginLinting(linter: Linter, filePath: string | null | undefined): void;
    didFinishLinting(linter: Linter, filePath: string | null | undefined): void;
    dispose(): void;
}
