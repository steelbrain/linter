import { CompositeDisposable } from 'atom';
import type { LinterMessage } from '../types';
export declare type TreeViewHighlight = {
    info: boolean;
    error: boolean;
    warning: boolean;
};
export default class TreeView {
    messages: Array<LinterMessage>;
    decorations: Record<string, TreeViewHighlight>;
    subscriptions: CompositeDisposable;
    decorateOnTreeView?: 'Files and Directories' | 'Files' | 'None';
    constructor();
    update(givenMessages?: Array<LinterMessage> | null | undefined): void;
    applyDecorations(decorations: Record<string, TreeViewHighlight>): void;
    dispose(): void;
    static getElement(): HTMLElement | null;
    static getElementByPath(parent: HTMLElement, filePath: string): HTMLElement | null;
}
