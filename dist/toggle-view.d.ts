import { CompositeDisposable, Emitter, Disposable } from 'atom';
declare type ToggleAction = 'enable' | 'disable';
declare class ToggleProviders {
    action: ToggleAction;
    emitter: Emitter;
    providers: Array<string>;
    subscriptions: CompositeDisposable;
    disabledProviders: Array<string>;
    constructor(action: ToggleAction, providers: Array<string>);
    getItems(): Promise<Array<string>>;
    process(name: string): Promise<void>;
    show(): Promise<void>;
    onDidDispose(callback: () => any): Disposable;
    onDidDisable(callback: (name: string) => any): Disposable;
    dispose(): void;
}
export default ToggleProviders;
