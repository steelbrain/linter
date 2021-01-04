import { CompositeDisposable, Emitter } from 'atom';
import type { Disposable, TextBuffer } from 'atom';
import type { MessagesPatch, Message, Linter } from './types';
declare type Linter$Message$Map = {
    buffer: TextBuffer | null | undefined;
    linter: Linter;
    changed: boolean;
    deleted: boolean;
    messages: Array<Message>;
    oldMessages: Array<Message>;
};
declare class MessageRegistry {
    emitter: Emitter;
    messages: Array<Message>;
    messagesMap: Set<Linter$Message$Map>;
    subscriptions: CompositeDisposable;
    debouncedUpdate: () => void;
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
export default MessageRegistry;
