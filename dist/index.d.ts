import { Disposable } from 'atom';
import type { UI, Linter as LinterProvider, Indie } from './types';
export declare function activate(): void;
export declare function consumeLinter(linter: LinterProvider): Disposable;
export declare function consumeUI(ui: UI): Disposable;
export declare function provideIndie(): (indie: Indie) => import("./indie-delegate").default;
export declare function deactivate(): void;
