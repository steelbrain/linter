import { Range, Point, TextEditor } from 'atom';
export declare type Message = {
    key: string;
    version: 2;
    linterName: string;
    location: {
        file: string;
        position: Range;
    };
    reference?: {
        file: string;
        position?: Point;
    };
    url?: string;
    icon?: string;
    excerpt: string;
    severity: 'error' | 'warning' | 'info';
    solutions?: Array<{
        title?: string;
        position: Range;
        priority?: number;
        currentText?: string;
        replaceWith: string;
    } | {
        title?: string;
        priority?: number;
        position: Range;
        apply: () => any;
    }>;
    description?: string | (() => Promise<string> | string);
};
export declare type LinterResult = Array<Message> | null;
export declare type Linter = {
    __$sb_linter_version: number;
    __$sb_linter_activated: boolean;
    __$sb_linter_request_latest: number;
    __$sb_linter_request_last_received: number;
    name: string;
    scope: 'file' | 'project';
    lintOnFly?: boolean;
    lintsOnChange?: boolean;
    grammarScopes: Array<string>;
    lint(textEditor: TextEditor): LinterResult | Promise<LinterResult>;
};
export declare type Indie = {
    name: string;
};
export declare type MessagesPatch = {
    added: Array<Message>;
    removed: Array<Message>;
    messages: Array<Message>;
};
export declare type UI = {
    name: string;
    didBeginLinting(linter: Linter, filePath: string | null | undefined): void;
    didFinishLinting(linter: Linter, filePath: string | null | undefined): void;
    render(patch: MessagesPatch): void;
    dispose(): void;
};
declare module 'atom' {
    interface CompositeDisposable {
        disposed: boolean;
    }
    interface Pane {
        getPendingItem(): TextEditor;
    }
    interface Notification {
        getOptions(): {
            detail: string;
        };
    }
}
export declare type RequestIdleCallbackHandle = any;
declare type RequestIdleCallbackOptions = {
    timeout: number;
};
declare type RequestIdleCallbackDeadline = {
    readonly didTimeout: boolean;
    timeRemaining: () => number;
};
declare global {
    interface Window {
        requestIdleCallback: (callback: (deadline: RequestIdleCallbackDeadline) => void, opts?: RequestIdleCallbackOptions) => RequestIdleCallbackHandle;
        cancelIdleCallback: (handle: RequestIdleCallbackHandle) => void;
    }
}
export {};
