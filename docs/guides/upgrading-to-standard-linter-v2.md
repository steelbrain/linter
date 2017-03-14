# Upgrading to Standard Linter v2

This upgrade guide assumes your package currently implements [Standard Linter API v1][]
and [Message API v1][].

## package.json

You need to update the version in the manifest for `linter` service from
`1.x.x` to `2.0.0`.

### Before

```cjson
{
  # stuff above
  "providedServices": {
    "linter": {
      "versions": {
        "1.0.0": "provideLinter"
      }
    }
  },
  # stuff below
}
```

### After

```cjson
{
  # stuff above
  "providedServices": {
    "linter": {
      "versions": {
        "2.0.0": "provideLinter"
      }
    }
  },
  # stuff below
}
```

## index.js

The new Message format is quite different from the v1 format, although all the
essential elements are still there. The changes in required information are:

*   `type` is no longer allowed and...

*   `severity` is now mandatory

*   `text` is renamed to `excerpt`

*   `html` is no longer allowed, similar functionality is available as
    `description` which is either a string or a function (Promise) returning a
    string which is then rendered as Markdown.

*   `name` is no longer allowed

*   `filePath` and `range` have been combined into a mandatory `location`
    property

*   `trace` no longer exists, the functionality has been split into `reference`
    (for the `location` equivalent) and `url` for an external http url.

*   `fix` has been replaced with `solutions`, which is far more flexible.

*   `selected` is no longer allowed (since you can now provide a `reference` and
    `url`)

As for the provider itself, `lintOnFly` is now `lintsOnChange` and the `name` attribute is now mandatory.

### Before

```js
export function provideLinter() {
  const linter = {
    scope: 'file',
    lintOnFly: false,
    grammarScopes: ['source.js'],
    lint() {
      return [{
        type: 'Error',
        filePath: '/etc/passwd',
        range: [[0, 0], [0, 1]],
        text: 'This is the start, of something beautiful',
      }]
    }
  }

  return linter
}
```

### After

```js
export function provideLinter() {
  const linter = {
    name: 'Example',
    scope: 'file',
    lintsOnChange: false,
    grammarScopes: ['source.js'],
    lint() {
      return [{
        severity: 'error',
        location: {
          file: '/etc/passwd',
          position: [[0, 0], [0, 1]],
        },
        excerpt: 'This is the start, of something beautiful'
      }]
    }
  }

  return linter
}
```

## Other Changes

-   In Linter 1.x, you could return any non-Array value to make linter re-use
    last results. In Linter 2.x, you must return either an Array or `null`,
    returning `false` or `undefined` will be considered an error.

[Standard Linter API v1]: https://github.com/steelbrain/linter/blob/v1/docs/types/standard-linter-v1.md
[Message API v1]: https://github.com/steelbrain/linter/blob/v1/docs/types/linter-message-v1.md
