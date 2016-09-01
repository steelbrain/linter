# Standard Linter v2

This document describes the type of Standard Linter v2, for an example in how to implement this in your own package see the see the [Example Usage](../examples/standard-linter-v2.md) document.

## Type

```js
type Linter = {
  // Automatically added, not guaranteed
  __$sb_linter_version: 2,
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
```

## FAQs

**Q**: What's the difference between `file` and `project` scopes?

**A**: Their newer results only replace their previous results for that particular file. Examples of such linters are `ESLint`.

Results of `project` scoped linters are not tied to any TextEditor and are not discarded even when all TextEditors are disposed. Their new results replace all of their previous results. This is useful for linters that run background daemons that scan the entire project, `FlowType` for example.

**Q**: What's the purpose of `lintOnFly`?

**A**: If lintOnFly is false, the linter is only triggered when the user saves a file. But when set to true, it also invokes the linter every time the user stops typing, after a user configurable delay.

**Q**: What should I set my `lintOnFly` to?

**A**: Only set it to true if your linter provider lints the buffer contents (and you pass them to it), otherwise just set it to false. Setting it to true while the linter only lints the contents on disk would be unnecessary because the contents of the file in buffer and disk would be different.

**Q**: What value do I use for `grammarScopes`?

**A**: grammarScopes is an array of scopes the linter should be invoked on, set your cursor in an editor and execute `Editor: Log Cursor Scope` command, you'll get something like `source.js` or `source.gfm`, that's what you should put in `grammarScopes`.

**Q**: How do I make my provider trigger for all file types?

**A**: Use `['*']` as the `grammarScopes` value, and it'll be triggered regardless of scope.
