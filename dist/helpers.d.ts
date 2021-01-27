import type { TextEditor } from 'atom';
import type { Linter, Message } from './types';
export declare const $version = "__$sb_linter_version";
export declare const $activated = "__$sb_linter_activated";
export declare const $requestLatest = "__$sb_linter_request_latest";
export declare const $requestLastReceived = "__$sb_linter_request_last_received";
export declare function shouldTriggerLinter(linter: Linter, wasTriggeredOnChange: boolean, scopes: Array<string>): boolean;
export declare function getEditorCursorScopes(textEditor: TextEditor): Array<string>;
export declare function isPathIgnored(filePath: string | null | undefined, ignoredGlob: string, ignoredVCS: boolean): Promise<boolean>;
export declare function updateMessageKey(message: Message): void;
export declare function normalizeMessages(linterName: string, messages: Array<Message>): void;
export declare function updateKeys(messages: Array<Message>): void;
export declare function createKeyMessageMap(messages: Array<Message>): Map<string, Message>;
interface FlaggedMessages {
    oldKept: Array<Message>;
    oldRemoved: Array<Message>;
    newAdded: Array<Message>;
}
export declare function flagMessages(inputs: Array<Message>, oldMessages: Array<Message>): FlaggedMessages | null;
export declare function mergeArray(arr1: Array<any>, arr2: Array<any>): void;
export {};
