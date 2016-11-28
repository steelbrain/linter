# Indie Linter v2

This document describes the type of Indie Linter v2, for an example in how to
implement this in your own package see the see the [Example Usage][] document.

## Types

There are two different types in the Indie Linter v2 API. `Config` is the value
you input to `registerIndie` (the param of your `consumeIndie` function), it's
return value is an `IndieDelegate`.

### Config

```js
{
  name: string,
}
```

### IndieDelegate

```js
class IndieDelegate {
  get name(): string;
  getMessages(): Array<Message>;
  clearMessages(): void;
  setMessages(filePath: string, messages: Array<Message>): void;
  setAllMessages(messages: Array<Message>): void;
  onDidUpdate(callback: Function): Disposable
  onDidDestroy(callback: Function): Disposable
  dispose(): void
}
```

## FAQs

**Q**: What's the difference between `setMessages` and `setAllMessages`?

**A**:

*   `setMessages` replaces the last stored messages for the given `filePath` for
    your delegate. All messages provided must have the same `location.path` as
    the given `filePath`.

*   `setAllMessages` replaces the list of messages Linter has stored for your
    provider. Any existing messages, regardless of the file they are associated
    with, are discarded.

[Example Usage]: ../examples/indie-linter-v2.md
