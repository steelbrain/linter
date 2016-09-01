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
  source?: {
    file: string,
    position?: Point,
  },
  excerpt: string,
  severity: 'error' | 'warning' | 'info',
  reference?: string,
  solutions?: Array<{
    title?: string,
    position: Range,
    currentText?: string,
    replaceWith: string,
  } | {
    title?: string,
    position: Range,
    apply: (() => any),
  }>,
  // NOTE: description is a markdown string or a function that returns a markdown string or a promise that resolves to a markdown string
  description: string | (() => Promise<string> | string)
}

export type MessageLegacy = {
  // Automatically added
  key: string,
  version: 1,
  linterName: string,

  // From providers
  type: string,
  text?: string,
  html?: string,
  filePath?: string,
  range?: Range,
  class?: string,
  severity: 'error' | 'warning' | 'info',
  trace?: Array<MessageLegacy>,
  fix?: {
    range: Range,
    newText: string,
    oldText?: string
  }
}

export type Linter = {
  // Automatically added
  __$sb_linter_version: number,
  __$sb_linter_activated: boolean,
  __$sb_linter_request_latest: number,
  __$sb_linter_request_last_received: number,

  // From providers
  name: string,
  scope: 'file' | 'project',
  lintOnFly: boolean,
  grammarScopes: Array<string>,
  lint(textEditor: TextEditor): ?Array<Message | MessageLegacy> | Promise<?Array<Message | MessageLegacy>>,
}

export type Indie = {
  name: string
}

export type MessagesPatch = {
  added: Array<Message | MessageLegacy>,
  removed: Array<Message | MessageLegacy>,
  messages: Array<Message | MessageLegacy>,
}

export type UI = {
  name: string,
  didBeginLinting(linter: Linter, filePath: ?string): void,
  didFinishLinting(linter: Linter, filePath: ?string): void,
  render(patch: MessagesPatch): void,
  dispose(): void
}

export type State = { }
