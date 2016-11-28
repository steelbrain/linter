# Upgrading to Indie Linter v2

This upgrade guide assumes your package current implements [Indie Linter API v1][]
and [Message API v1][].

## package.json

You need to update the version in the manifest for `linter-indie` service from
`1.x.x` to `2.0.0`.

### Before

```cjson
{
  # stuff above
  "consumedServices": {
    "linter-indie": {
      "versions": {
        "1.0.0": "consumeIndie"
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
  "consumedServices": {
    "linter-indie": {
      "versions": {
        "2.0.0": "consumeIndie"
      }
    }
  },
  # stuff below
}
```

## index.js

You can restructure your package to use the new `IndieDelegate::setMessages`
method that is per file, but to keep this guide simple we're only going to
upgrade from the old `IndieDelegate::setMessages` to
`IndieDelegate::setAllMessages` because these two methods are functionally
identical.

The Message format used also needs to be updated to match the new
[Message API v2][] format.

### Before

```js
export function consumeIndie(registry) {
  const indie = registry.register({
    name: 'Example',
  })

  indie.setMessages([{
    type: 'Error',
    filePath: '/etc/passwd',
    range: [[0, 0], [0, 1]],
    text: 'MURICAA! F YEAH!',
  }])
}
```

### After

```js
export function consumeIndie(registerIndie) {
  const indie = registerIndie({
    name: 'Example',
  })

  indie.setAllMessages([{
    severity: 'error',
    location: {
      file: '/etc/passwd',
      position: [[0, 0], [0, 1]]
    },
    excerpt: 'MURICAA! F YEAH!',
  }])
}
```

[Indie Linter API v1]: https://github.com/steelbrain/linter/blob/v1/docs/types/indie-linter-v1.md
[Message API v1]: https://github.com/steelbrain/linter/blob/v1/docs/types/linter-message-v1.md
[Message API v2]: ../types/linter-message-v2.md
