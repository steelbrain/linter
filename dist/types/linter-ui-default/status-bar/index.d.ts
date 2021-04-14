import { CompositeDisposable } from 'atom';
import type { StatusBar as StatusBarRegistry } from 'atom/status-bar';
import Element from './element';
import type { LinterMessage } from '../types';
export default class StatusBar {
    element: Element;
    messages: Array<LinterMessage>;
    subscriptions: CompositeDisposable;
    statusBarRepresents?: 'Entire Project' | 'Current File';
    statusBarClickBehavior?: 'Toggle Panel' | 'Jump to next issue' | 'Toggle Status Bar Scope';
    constructor();
    update(messages?: Array<LinterMessage> | null | undefined): void;
    attach(statusBarRegistry: StatusBarRegistry): void;
    dispose(): void;
}
