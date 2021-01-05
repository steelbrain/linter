import type { UI, Linter as LinterProvider, Indie } from './types';
declare class Linter {
    private commands;
    private registryUI?;
    private registryIndie?;
    private registryEditors?;
    private registryLinters?;
    private registryMessages?;
    private subscriptions;
    private idleCallbacks;
    constructor();
    dispose(): void;
    registryEditorsInit(): void;
    registryLintersInit(): void;
    registryIndieInit(): void;
    registryMessagesInit(): void;
    registryUIInit(): void;
    addUI(ui: UI): void;
    deleteUI(ui: UI): void;
    addLinter(linter: LinterProvider): void;
    deleteLinter(linter: LinterProvider): void;
    addIndie(indie: Indie): import("./indie-delegate").default;
}
export default Linter;
