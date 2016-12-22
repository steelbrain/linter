# Linter Message v2

This document describes the type of Linter Message v2. It's supported in
[`Indie Linter v2`][] and [`Standard Linter v2`][].

## Type

```js
type Message = {
  // Automatically added for UI consumers, do not specify in a provider
  key: string,
  version: 2,
  linterName: string,

  // From providers
  location: {
    file: string,
    position: Range,
  },
  reference?: {
    file: string,
    position?: Point,
  },
  icon?: string,
  excerpt: string,
  severity: 'error' | 'warning' | 'info',
  url?: string, // external HTTP link
  solutions?: Array<{
    title?: string,
    position: Range,
    priority?: number,
    currentText?: string,
    replaceWith: string,
  } | {
    title?: string,
    position: Range,
    priority?: number,
    apply: (() => any),
  }>,
  description?: string | (() => Promise<string> | string)
}
```

## FAQs

**Q**: Which properties are optional?

**A**: The type above uses [`flowtype`][], `?` with the key
indicates that it's optional and can be falsy.

**Q**: What are the valid values for `icon` attribute?

**A**: Depends on the UI provider, the default Linter UI uses this attribute to
determine the octicon to show in gutter.

**Q**: What type of value to add in `description`?

**A**: The description property uses Markdown, and also accepts a callback that
resolves to a Markdown string. You can use it to provide in-editor description
of the error using longer running tasks, such as making an HTTP request.

**Q**: What to do in the `apply` callback of a solution?

**A**: That's entirely up to you, you can manipulate the editor text or do
something else. If you just want to replace some simple text in the editor, use
the other solution type that was specifically built for text replacement.

**Q**: What's the purpose of the `title` in a solution?

**A**: Depends on the UI provider, the default Linter UI uses this attribute as
it's title for [Intentions][] package,
`Fix linter error` is the default one used at the time of writing this document.

**Q**: What is the purpose of the `priority` attribute in a solution?

**A**: This attribute determines the auto-applied solution if the user invokes a
apply all solutions command. This priority is only relevant to other solutions in
the same message.

**Q**: What is `Point` and `Range`?

**A**: These are references to built in [`Point`][] and [`Range`][] classes.

[`Indie Linter v2`]: indie-linter-v2.md
[`Standard Linter v2`]: standard-linter-v2.md
[`flowtype`]: https://flowtype.org/
[Intentions]: https://atom.io/packages/intentions
[`Point`]: https://atom.io/docs/api/latest/Point
[`Range`]: https://atom.io/docs/api/latest/Range
