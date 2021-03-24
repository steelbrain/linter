import { Disposable } from 'atom';
declare type ToggleAction = 'enable' | 'disable';
export default class ToggleView {
    private action;
    private emitter;
    private providers;
    private subscriptions;
    private disabledProviders;
    constructor(action: ToggleAction, providers: Array<string>);
    getItems(): Array<string>;
    process(name: string): void;
    show(): void;
    onDidDispose(callback: () => any): Disposable;
    onDidDisable(callback: (name: string) => any): Disposable;
    dispose(): void;
}
export {};
