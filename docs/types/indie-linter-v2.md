# Indie Linter v2

This document describes the type of Indie Linter v2, see the [Example Usage](../examples/indie-linter-v2.md) document for usage info.

## Types

There are two different types in the Indie Linter v2 API. `Indie` is the value you input to `IndieRegistry::register`, it's return value is `IndieDelegate`

### Indie

```js
{
  name: string,
}
```

### IndieDelegate

```js
class IndieDelegate {
  get name(): string;
  getMessages: Array<Message>;
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

**A**: `setMessages` only clears messages of the given file path and replaces them with the given value. `setAllMessages` clears all last messages and splits them into groups of filePaths itself.
