import { Emitter, CompositeDisposable } from 'atom';
import type { Disposable } from 'atom';
import type { Indie, Message } from './types';
export default class IndieDelegate {
    indie: Indie;
    scope: 'project';
    emitter: Emitter;
    version: 2;
    messages: Map<string | null | undefined, Array<Message>>;
    subscriptions: CompositeDisposable;
    constructor(indie: Indie, version: 2);
    get name(): string;
    getMessages(): Array<Message>;
    clearMessages(): void;
    setMessages(filePath: string | Array<Record<string, any>>, messages?: Array<Message> | null | undefined): void;
    setAllMessages(messages: Array<Message>): void;
    onDidUpdate(callback: (...args: Array<any>) => any): Disposable;
    onDidDestroy(callback: (...args: Array<any>) => any): Disposable;
    dispose(): void;
}
