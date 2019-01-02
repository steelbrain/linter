/* @flow */

import type { Range, Point, TextEditor } from 'atom'

export type Message = {
  // Automatically added
  key: string,
  version: 2,
  linterName: string,

  // From providers
  location: {
    file: string,
    position: Range,
  },
  reference?: {
    file: string,
    position?: Point,
  },
  url?: string,
  icon?: string,
  excerpt: string,
  severity: 'error' | 'warning' | 'info',
  solutions?: Array<
    | {
        title?: string,
        position: Range,
        priority?: number,
        currentText?: string,
        replaceWith: string,
      }
    | {
        title?: string,
        priority?: number,
        position: Range,
        apply: () => any,
      },
  >,
  description?: string | (() => Promise<string> | string),
}

export type LinterResult = Array<Message> | null
export type Linter = {
  // Automatically added
  __$sb_linter_version: number,
  __$sb_linter_activated: boolean,
  __$sb_linter_request_latest: number,
  __$sb_linter_request_last_received: number,

  // From providers
  name: string,
  scope: 'file' | 'project',
  lintOnFly?: boolean, // <-- legacy
  lintsOnChange?: boolean,
  grammarScopes: Array<string>,
  lint(textEditor: TextEditor): LinterResult | Promise<LinterResult>,
}

export type Indie = {
  name: string,
}

export type MessagesPatch = {
  added: Array<Message>,
  removed: Array<Message>,
  messages: Array<Message>,
}

export type UI = {
  name: string,
  didBeginLinting(linter: Linter, filePath: ?string): void,
  didFinishLinting(linter: Linter, filePath: ?string): void,
  render(patch: MessagesPatch): void,
  dispose(): void,
}
