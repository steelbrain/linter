import type { LinterMessage, ListItem } from './types';
import type { TextEditor, Point } from 'atom';
export default class Intentions {
    messages: Array<LinterMessage>;
    grammarScopes: Array<string>;
    getIntentions({ textEditor, bufferPosition }: {
        textEditor: TextEditor;
        bufferPosition: Point;
    }): ListItem[];
    update(messages: Array<LinterMessage>): void;
}
