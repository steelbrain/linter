# Linter Message v1

This document describes the types associated with Linter v1 messages. They
are supported in [`Indie Linter v1`](indie-linter-v1.md) and
[`Standard Linter v1`](standard-linter-v1.md).

## Message

```js
type Message = {
  // Automatically added for internal Linter use, do not specify in a provider
  key: string,
  version: 1,
  linterName: string,

  // From providers
  type: string,
  text?: string,
  html?: string,
  name?: string,
  // ^ Only specify this if you want the name to be something other than your linterProvider.name
  // WARNING: There is NO replacement for this in v2
  filePath?: string,
  // ^ MUST be an absolute path (relative paths are not supported)
  range?: Range,
  trace?: Array<Trace>,
  fix?: Fix,
  severity?: 'error' | 'warning' | 'info',
  selected?: Function
  // ^ WARNING: There is NO replacement for this in v2
}
```

__Note:__ Although both `text` and `html` are marked as optional, you **must**
provide one of them. Please note that providing both is an error.

## Trace

`Trace` objects can be used to provide traces or references to other files or
positions. The type of traces can be anything, but is recommended to be
`'Trace'` for visual ease.

![Screenshot](https://cloud.githubusercontent.com/assets/4278113/10680812/6ecf6d64-78e0-11e5-972b-4a47261d19e3.png)

```js
type Trace = {
  type: 'Trace',
  text?: string,
  html?: string,
  name?: string,
  // ^ Only specify this if you want the name to be something other than your linterProvider.name
  // WARNING: There is NO replacement for this in v2
  filePath?: string,
  // ^ MUST be an absolute path (relative paths are not supported)
  range?: Range,
  class?: string,
  severity?: 'error' | 'warning' | 'info'
}
```

## Fix

`Fix` objects allow a linter to suggest a possible fix to the user for a
message.

```js
type Fix = {
  range: Range,
  newText: string,
  oldText?: string
}
```

## Registering Custom Types

Linter comes with three default Message Types `Error`, `Warning` and `Trace`.
If these types don't suit your needs and you want to create your own, it's
as easy as pie.

All you have to do is add a type of your choice to the message object and add
CSS for the lowercase version of that type, for example if the type is
`Info` it's style would be `info`:

```css
/* Ref: https://github.com/atom/one-dark-ui/blob/master/styles/ui-variables.less */
@import "ui-variables";
atom-text-editor::shadow .linter-highlight, .linter-highlight {
  &.info {
    /* Style for Message Badges */
    &:not(.line-number) {
      background-color: @background-color-info;
      color: white;
    }
    /* Style for Gutter */
    .linter-gutter {
      color: @background-color-info;
    }
    /* Style for the text editor highlight */
    .region {
      border-bottom: 1px dashed @background-color-info;
    }
  }
}
```

__Note:__ Spaces in Types are converted to dashes for CSS classes.

__Warning:__ Custom File Types have been dropped in v2 in favor of three severities. Providers can still provide custom severity labels in message markups.

## FAQs

**Q**: Which properties are optional?

**A**: The type above uses [`flowtype`](https://flowtype.org/), `?` with the key
indicates that it's optional and can be "falsy".

**Q**: Where should the main content of the message go?

**A**: If you are just returning text, you should use the `text` property. Most
linter providers fall into this category. If you need to provide advanced
styling, or things like links then change to the `html` property. Note that you
should properly escape any content coming from your base linter before including
it in an `html` message.

**Q**: What to do in the `selected` callback?

**A**: That's entirely up to you, you can manipulate the editor text or do
something else.

**Q**: When is this called?

**A**: It is called whenever a user visits the message by either clicking on a trace or visiting the next message from their keyboard shortcuts.

**Q**: Where does `Range` come from?

**A**: This is a reference to the [`Range`](https://atom.io/docs/api/latest/Range)
class built into Atom.
