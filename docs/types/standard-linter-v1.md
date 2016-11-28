# Standard Linter v1

This document describes the type of Standard Linter v1, for an example in how to
implement this in your own package see the see the
[Example Usage](../examples/standard-linter-v1.md) document.

## Type

```js
type Linter = {
  // Automatically added, not guaranteed
  __$sb_linter_version: 1,
  __$sb_linter_activated: boolean,
  __$sb_linter_request_latest: number,
  __$sb_linter_request_last_received: number,

  // From providers
  name: string,
  scope: 'file' | 'project',
  lintOnFly: boolean,
  grammarScopes: Array<string>,
  lint(textEditor: TextEditor): ?Array<Message> | Promise<?Array<Message>>,
}
```

## FAQs

**Q**: What's the difference between `file` and `project` scopes?

**A**: `file` scoped Linter providers only return results for a single file.
Most of the base linters that a Linter provider is wrapping fall into this
category. Results of providers of this type are tied to an open TextEditor,
when it is closed all the associated messages are discarded.

`project` scoped Linter providers are meant for wrapping base linters that
provide results for multiple files at a time, eg. `flow`. Results of `project`
scoped linters are not tied to any specific TextEditor and are not discarded
even when all TextEditors are disposed. New results replace all previous
results.

**Q**: What's the purpose of `lintOnFly`?

**A**: If `lintOnFly` is false, the linter is only triggered when the user saves
a file. When set to true, it also invokes the linter every time the user stops
typing, after a delay configurable by the user in Linter's settings.

**Q**: What should I set `lintOnFly` to?

**A**: Only set it to `true` if you are able to run your base linter on the
current buffer contents, whether by passing them to it directly via `stdin`
(preferred), or by creating a temporary file. Setting it to true while the
linter only lints the contents on disk would cause Linter to repeatedly call
your provider during typing, leading to issues as the base linter may be
returning invalid results, but at the very least will be needlessly running.

**Q**: What value do I use for `grammarScopes`?

**A**: `grammarScopes` is an array of scopes your Linter provider should be
invoked on. To determine the proper value, put your cursor in an editor in a
location where you expect your provider to activate and run
`Editor: Log Cursor Scope` from the Atom Command Palette, you'll get a list of
scopes, one of which should start with "source". Choose the most specific
`source.___` entry as what you use in `grammarScopes`. If your base linter is
able to handle multiple types of files, enter each scope individually in the
array.

**Q**: How do I make my provider trigger for all file types?

**A**: Use `['*']` as the `grammarScopes` value, and it'll be triggered
regardless of the scope of the current file.

**Q**: How do I make linter use last messages for my provider?

**A**: Return `null` from your provider to make it re-use last messages.
