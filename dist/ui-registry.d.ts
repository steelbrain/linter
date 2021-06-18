import type { Linter, UI, MessagesPatch } from './types';
export default class UIRegistry {
    private providers;
    private subscriptions;
    add(ui: UI): void;
    delete(provider: UI): void;
    getProviders(): Array<UI>;
    render(messages: MessagesPatch): void;
    didBeginLinting(linter: Linter, filePath: string): void;
    didFinishLinting(linter: Linter, filePath: string): void;
    dispose(): void;
}
