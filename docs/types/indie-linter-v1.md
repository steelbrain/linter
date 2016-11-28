# Indie Linter v1

This document describes the type of Indie Linter v1, for an example in how to
implement this in your own package see the see the
[Example Usage](../examples/indie-linter-v1.md) document.

## Types

There are two different types in the Indie Linter v1 API. `Config`
is the value you input to `IndieRegistry.register` (the param of your `consumeLinter`
function), it's return value is an `Indie`.

### Config

```js
{
  name: string
}
```

### Indie

```js
class IndieRegistry {
  register(config: Config): Indie,
}
```

### Indie

```js
class Indie {
  deleteMessages(): void;
  setMessages(messages: Array<Message>): void;
  dispose(): void
}
```

## FAQs

**Q**: What's does `setMessages` do exactly?

**A**:

`setAllMessages` replaces the list of messages Linter has stored for your
provider. Any existing messages, regardless of the file they are associated
with, are discarded.
