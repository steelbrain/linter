import { TextEditor, Point } from 'atom'

// from intentions package:
// https://github.com/steelbrain/intentions/blob/master/lib/types.js
export type ListItem = {
  // // Automatically added
  readonly __$sb_intentions_class?: string

  // From providers
  icon?: string
  class?: string
  title: string
  priority: number
  selected(): void
}

export type IntentionsListProvider = {
  grammarScopes: Array<string>
  getIntentions(parameters: { textEditor: TextEditor; bufferPosition: Point }): Array<ListItem> | Promise<Array<ListItem>>
}
