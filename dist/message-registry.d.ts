import type { Disposable, TextBuffer } from 'atom';
import type { MessagesPatch, Message, Linter } from './types';
export default class MessageRegistry {
    private emitter;
    messages: Array<Message>;
    private messagesMap;
    private subscriptions;
    private debouncedUpdate;
    constructor();
    set({ messages, linter, buffer }: {
        messages: Array<Message>;
        linter: Linter;
        buffer: TextBuffer | null;
    }): void;
    update(): void;
    onDidUpdateMessages(callback: (difference: MessagesPatch) => void): Disposable;
    deleteByBuffer(buffer: TextBuffer): void;
    deleteByLinter(linter: Linter): void;
    dispose(): void;
}
