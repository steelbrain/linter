import { CompositeDisposable, Dock, WorkspaceCenter } from 'atom';
import type Delegate from './delegate';
export declare type PaneContainer = Dock & {
    state: {
        size: number;
    };
    render: Function;
    paneForItem: WorkspaceCenter['paneForItem'];
    location: string;
};
export default class PanelDock {
    element: HTMLElement;
    subscriptions: CompositeDisposable;
    panelHeight: number;
    alwaysTakeMinimumSpace: boolean;
    lastSetPaneHeight?: number;
    constructor(delegate: Delegate);
    doPanelResize(forConfigHeight?: boolean): void;
    getURI(): string;
    getTitle(): string;
    getDefaultLocation(): string;
    getAllowedLocations(): string[];
    getPreferredHeight(): any;
    dispose(): void;
}
