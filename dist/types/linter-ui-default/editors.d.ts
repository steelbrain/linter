import { CompositeDisposable } from 'atom';
import type { TextEditor } from 'atom';
import Editor from './editor';
import type { LinterMessage, MessagesPatch } from './types';
export declare type EditorsPatch = {
    added: Array<LinterMessage>;
    removed: Array<LinterMessage>;
    editors: Array<Editor>;
};
export declare type EditorsMap = Map<string, EditorsPatch>;
export default class Editors {
    editors: Set<Editor>;
    messages: Array<LinterMessage>;
    firstRender: boolean;
    subscriptions: CompositeDisposable;
    constructor();
    isFirstRender(): boolean;
    update({ messages, added, removed }: MessagesPatch): void;
    getEditor(textEditor: TextEditor): Editor | void;
    dispose(): void;
}
