'use babel'

export type Linter$UI = Object
export type Linter$State = {}
export type Linter$Linter = {
  name: string,
  scope: 'file' | 'project'
  grammarScopes: Array<string>,
  lint: Function
}
