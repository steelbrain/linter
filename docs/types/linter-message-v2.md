# Linter Message v2

This document describes the type of Linter Message v2. It's supported in
[Indie Linter v2][] and [Standard Linter v2][].

## Type

```js
type Message = {
  // NOTE: These are given by providers
  location: {
    file: string,
    // ^ MUST be an absolute path (relative paths are not supported)
    position: Range,
  },
  // ^ Location of the issue (aka where to highlight)
  reference?: {
    file: string,
    // ^ MUST be an absolute path (relative paths are not supported)
    position?: Point,
  },
  // ^ Reference to a different location in the editor, useful for jumping to classes etc.
  url?: string, // external HTTP link
  // ^ HTTP link to a resource explaining the issue. Default is a google search
  icon?: string,
  // ^ Name of octicon to show in gutter
  excerpt: string,
  // ^ Error message
  severity: 'error' | 'warning' | 'info',
  // ^ Severity of error
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
  // ^ Possible solutions to the error (user can invoke them at will)
  description?: string | (() => Promise<string> | string)
  // ^ Markdown long description of the error, accepts callback so you can do
  // http requests etc.
  linterName?: string,
  // ^ Optionally override the displayed linter name. Defaults to provider name.

  // NOTE: DO NOT SPECIFY THESE IN PROVIDER
  // Automatically added by base linter for UI consumers
  key: string,
  version: 2,
}
```

## FAQs

**Q**: Which properties are optional?

**A**: The type above uses [`flowtype`][], `?` with the key
indicates that it's optional and can be falsy.

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

[Indie Linter v2]: indie-linter-v2.md
[Standard Linter v2]: standard-linter-v2.md
[`flowtype`]: https://flowtype.org/
[Intentions]: https://atom.io/packages/intentions
[`Point`]: https://atom.io/docs/api/latest/Point
[`Range`]: https://atom.io/docs/api/latest/Range
