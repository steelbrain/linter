import { CompositeDisposable } from 'atom';
import type { Linter, UI, MessagesPatch } from './types';
declare class UIRegistry {
    providers: Set<UI>;
    subscriptions: CompositeDisposable;
    constructor();
    add(ui: UI): void;
    delete(provider: UI): void;
    getProviders(): Array<UI>;
    render(messages: MessagesPatch): void;
    didBeginLinting(linter: Linter, filePath?: string | null | undefined): void;
    didFinishLinting(linter: Linter, filePath?: string | null | undefined): void;
    dispose(): void;
}
export default UIRegistry;
