'use babel'

/* @flow */

export type Atom$Point = [number, number]
export type Atom$Range = [Atom$Point, Atom$Point] |
  {start: {row: number, column: number}, end: {row: number, column: number}}
export type Linter$Message = {
  key: string,
  type: string,
  text?: string,
  html?: string,
  name?: ?string,
  range?: Atom$Range,
  trace?: Array<Linter$Message>,
  severity: 'error' | 'warning' | 'info',
  filePath?: string,
  selected?: ((message: Linter$Message) => void)
}
export type Linter$State = {}
export type Linter$Linter = {
  name?: string,
  number: number,
  deactivated: boolean,
  scope: 'file' | 'project',
}
export type Linter$Regular = Linter$Linter & {
  grammarScopes: Array<string>,
  lint: Function
}
export type Linter$Indie = Linter$Linter & {

}
export type Linter$Difference = {
  added: Array<Linter$Message>,
  removed: Array<Linter$Message>,
  messages: Array<Linter$Message>
}
export type Linter$UI = {
  name?: string,
  activate(): void,
  didCalculateMessages(difference: Linter$Difference): void,
  didBeginLinting(linter: Linter$Regular, filePath: ?string): void,
  didFinishLinting(linter: Linter$Regular, filePath: ?string): void,
  dispose(): void
}
