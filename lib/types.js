'use babel'

/* @flow */

import type { Range, Point, TextEditor } from 'atom'

export type Message = {
  key: string, // <-- Automatically added
  version: 2, // <-- Automatically added
  linterName: string, // <-- Automatically added

  location: {
    file: string,
    position: Range,
  },
  source: ?{
    file: string,
    position?: Point,
  },
  excerpt: string,
  severity: 'error' | 'warning' | 'info',
  reference: ?string,
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
  description?: Array<string>,
}

export type MessageLegacy = {
  key: string, // <-- Automatically Added
  version: 1, // <-- Automatically added
  linterName: string, // <-- Automatically added

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
  name: string,
  scope: 'file' | 'project',
  lintOnFly: boolean,
  grammarScopes: Array<string>,
  lint: ((textEditor: TextEditor) => ?Array<Message | MessageLegacy> | Promise<?Array<Message | MessageLegacy>>),
}

export type LinterOld = {
  name: string,
  scope: 'file' | 'project',
  lintOnFly: boolean,
  grammarScopes: Array<string>,
  lint: ((textEditor: TextEditor) => ?Array<MessageLegacy> | Promise<?Array<MessageLegacy>>),
}

export type IndieConfig = {
  name: string
}

export type MessagesPatch = {
  added: Array<Message | MessageLegacy>,
  removed: Array<Message | MessageLegacy>,
  messages: Array<Message | MessageLegacy>,
}

export type UI = {
  name: string,
  activate(): void,
  didBeginLinting(linter: Linter, filePath: ?string): void,
  didFinishLinting(linter: Linter, filePath: ?string): void,
  render(patch: MessagesPatch): void,
  dispose(): void
}

export type State = { }
