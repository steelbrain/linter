import { CompositeDisposable } from 'atom';
import Panel from './panel';
import Commands from './commands';
import StatusBar from './status-bar';
import BusySignal from './busy-signal';
import Intentions from './intentions';
import type { Linter, LinterMessage, MessagesPatch } from './types';
import Editors from './editors';
import TreeView from './tree-view';
export default class LinterUI {
    name: string;
    panel?: Panel;
    signal: BusySignal;
    editors: Editors | null | undefined;
    treeview?: TreeView;
    commands: Commands;
    messages: Array<LinterMessage>;
    statusBar: StatusBar;
    intentions: Intentions;
    subscriptions: CompositeDisposable;
    idleCallbacks: Set<number>;
    constructor();
    render(difference: MessagesPatch): void;
    didBeginLinting(linter: Linter, filePath: string): void;
    didFinishLinting(linter: Linter, filePath: string): void;
    dispose(): void;
}
