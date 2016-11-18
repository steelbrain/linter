# Self (internal) API

Linter's self service provides an API for External Packages to manipulate
Linter's messages, subscribe to message events, and more. For an example of how
to implement this in your own package see the see the
[Example Usage](../examples/self-linter-v1.md) document.

**Note**: Compatibility in self API is not guaranteed and can be broken at
any point. We will however try to ping package authors which use the self
API services being removed but no guarantees!!

## Defining a consumer

You'll need to add this in your package's package.json file:

```json
"consumedServices": {
  "linter-plus-self": {
    "versions": {
      "0.1.0": "consumeLinter"
    }
  }
}
```
You'll be provided with Linter's main instance in your main file's consumeLinter method

## Types

Note: The `Message` type is defined in the [Message v1 Type](linter-message-v1.md).

```js
type Linter = {
  grammarScopes: array<string>
  scope: enum{'file', 'project'}
  lintOnFly: bool
  lint: function<TextEditor>
}

class Linter {
  views: LinterViews
  commands: LinterCommands

  addLinter(linter: Linter): void
  deleteLinter(linter: Linter): void
  hasLinter(linter: Linter): bool
  getLinters(): Set<Linter>
  setMessages(linter: Linter, messages: array<Message>): void
  deleteMessages(linter: Linter): void
  getMessages(): array<Message>
  onDidUpdateMessages(callback:Function<{linter, messages, editor}>)
  getActiveEditorLinter(): ?EditorLinter
  getEditorLinter(textEditor: TextEditor): ?EditorLinter
  eachEditorLinter(callback: Function<EditorLinter>): void
  observeEditorLinters(callback: Function<EditorLinter>): Disposible
}

class EditorLinter {
  getMessages(): array<Message>
  onDidMessageAdd(callback: Function<Message>): Disposable
  onDidMessageDelete(callback: Function<Message>): Disposable
  onDidMessageChange(callback: Function<{type: enum{'add', 'delete'}, message: Message}>)
  onDidCalculateLineMessages(callback: Function): void
  onDidDestroy(callback: Function): void
}

class LinterViews {
  render({added, removed, messages}): void
  updateCounts(): void
  renderBubble(?editorLinter): void
}

class LinterCommands {
  toggleLinter(): void // Toggles the active editor linter
  lint(): void
  nextError(): void // Points the user cursor to next error location
}
```
