# UI Provider v1

This document describes the type of UI Provider v1, for an example in how to
implement this in your own package see the see the [Example Usage][] document.

## Type

```js
type UI = {
  name: string,
  didBeginLinting(linter: Linter, filePath: ?string): void,
  didFinishLinting(linter: Linter, filePath: ?string): void,
  render(patch: MessagesPatch): void,
  dispose(): void
}
```

## FAQs

**Q**: Which versions of messages may the UI provider receive?

**A**: The UI provider may receive any version of messages the base linter can
accept depending on the providers.

**Q**: Under what circumstances is the `filePath` null for
`onDid{Begin,Finish}Linting`?

**A**: It's null for editors that are not tied to a specific editor
(i.e. project-scoped ones).

**Q**: What is the proper place to run the activation logic?

**A**: The `provideUI` or similar function in your package where you return the
UI object is the best place to run the activation logic.

**Q**: What is the `dispose` for and when is it triggered?

**A**: It is triggered when either your package or the linter package is
deactivated. It's useful for destroying any Panels you might have registered for
the UI.

[Example Usage]: ../examples/ui-provider-v1.md
