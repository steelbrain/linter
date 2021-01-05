import { Disposable } from 'atom';
declare type ToggleAction = 'enable' | 'disable';
export default class ToggleProviders {
    private action;
    private emitter;
    private providers;
    private subscriptions;
    private disabledProviders;
    constructor(action: ToggleAction, providers: Array<string>);
    getItems(): Promise<Array<string>>;
    process(name: string): Promise<void>;
    show(): Promise<void>;
    onDidDispose(callback: () => any): Disposable;
    onDidDisable(callback: (name: string) => any): Disposable;
    dispose(): void;
}
export {};
