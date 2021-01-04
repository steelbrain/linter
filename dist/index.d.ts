import { Disposable } from 'atom';
import type { UI, Linter as LinterProvider, Indie } from './types';
export declare function activate(): void;
export declare function consumeLinter(linter: LinterProvider | Array<LinterProvider>): Disposable;
export declare function consumeUI(ui: UI | Array<UI>): Disposable;
export declare function provideIndie(): (indie: Indie) => import("./indie-delegate").default;
export declare function deactivate(): void;
