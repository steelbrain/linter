import { CompositeDisposable, Emitter } from 'atom';
import type { Disposable, Point, TextEditor, DisplayMarker } from 'atom';
import type { LinterMessage } from '../types';
export default class TooltipElement {
    marker: DisplayMarker;
    element: HTMLElement;
    emitter: Emitter<{
        'did-destroy': never;
    }, {}>;
    messages: Array<LinterMessage>;
    subscriptions: CompositeDisposable;
    constructor(messages: Array<LinterMessage>, position: Point, textEditor: TextEditor);
    isValid(position: Point, messages: Map<string, LinterMessage>): boolean;
    onDidDestroy(callback: () => void): Disposable;
    dispose(): void;
}
