import { CompositeDisposable, Disposable, Emitter, Range } from 'atom';
declare type CompositeDisposableType = CompositeDisposable & {
    disposed: boolean;
};
import type { TextEditor, DisplayMarker, Marker, Gutter, Point, Cursor } from 'atom';
import Tooltip from '../tooltip';
import type { LinterMessage } from '../types';
export default class Editor {
    textEditor: TextEditor;
    gutter: Gutter | null;
    tooltip: Tooltip | null;
    emitter: Emitter<{
        'did-destroy': never;
    }, {}>;
    markers: Map<string, (DisplayMarker | Marker)[]>;
    messages: Map<string, import("../types").Message>;
    showTooltip: boolean;
    subscriptions: CompositeDisposableType;
    cursorPosition: Point | null;
    gutterPosition?: string;
    tooltipFollows: string;
    showDecorations?: boolean;
    showProviderName: boolean;
    ignoreTooltipInvocation: boolean;
    currentLineMarker: DisplayMarker | null;
    lastRange?: Range;
    lastIsEmpty?: boolean;
    lastCursorPositions: WeakMap<Cursor, Point>;
    constructor(textEditor: TextEditor);
    listenForCurrentLine(): void;
    listenForMouseMovement(): any;
    listenForKeyboardMovement(): Disposable;
    updateGutter(): void;
    removeGutter(): void;
    updateTooltip(position: Point | null | undefined): void;
    removeTooltip(): void;
    apply(added: Array<LinterMessage>, removed: Array<LinterMessage>): void;
    decorateMarker(message: LinterMessage, marker: DisplayMarker | Marker, paint?: 'gutter' | 'editor' | 'both'): void;
    saveMarker(key: string, marker: DisplayMarker | Marker): void;
    destroyMarker(key: string): void;
    onDidDestroy(callback: (value?: any) => void): Disposable;
    dispose(): void;
}
export {};
