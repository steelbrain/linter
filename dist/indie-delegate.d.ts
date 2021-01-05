import type { Disposable } from 'atom';
import type { Indie, Message } from './types';
export default class IndieDelegate {
    private indie;
    scope: 'project';
    private emitter;
    version: 2;
    private messages;
    private subscriptions;
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
