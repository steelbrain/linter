'use babel'

/* @flow */

import type { Range, Point, TextEditor } from 'atom'

export type Message = {
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
  reference: string,
  description: ?string,
}

export type Linter = {
  name: string,
  scope: 'file' | 'project',
  // TODO: Use a Symbol for these
  // --
  deactivated: boolean,
  request_latest: number,
  request_last_received: number,
  // --
  grammarScopes: Array<string>,
  lint: ((textEditor: TextEditor) => ?Array<Message> | Promise<?Array<Message>>),
}

export type IndieConfig = {
  name: string
}

export type MessagesPatch = {
  added: Array<Message>,
  removed: Array<Message>,
  messages: Array<Message>,
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
