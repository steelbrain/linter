'use babel'

export type Linter$Message = {
  type: string,
  text?: string,
  html?: string,
  name?: string,
  filePath?: string,
  range?: Atom$Range,
  trace?: Array<Linter$Message>
}
export type Linter$State = {}
export type Linter$Linter = {
  name?: string,
  scope: 'file' | 'project'
  grammarScopes: Array<string>,
  lint: Function
}
export type Linter$UI = {
  name?: string,
  activate(): void,
  didCalculateMessages({added, removed, messages}: Linter$Difference): void,
  didBeginLinting(linter: Linter$Linter, filePath: string): void,
  didFinishLinting(linter: Linter$Linter, filePath: string): void,
  dispose(): void
}
export type Linter$Difference = {
  added: Array<Linter$Message>,
  removed: Array<Linter$Message>,
  messages: Array<Linter$Message>
}