# Upgrading to Indie Linter v2

This upgrade guide assumes your package uses Indie Linter API v1 and Message API v1.

## package.json

You need to update the version in the manifest for `linter-indie` service from `1.x.x` to `2.0.0`.

**Before:**

```
... stuff above
  "consumedServices": {
    "linter-indie": {
      "versions": {
        "1.0.0": "consumeIndie"
      }
    }
  },
... stuff below
```

**After:**

```
... stuff above
  "consumedServices": {
    "linter-indie": {
      "versions": {
        "2.0.0": "consumeIndie"
      }
    }
  },
... stuff below
```

## index.js

You can restructure your package to use the new `NewIndieDelegate::setMessages` method that is per file, but to keep this guide simple we're gonna upgrade from `OldIndieDelegate::setMessages` to `NewIndieDelegate::setAllMessages` because these two methods are identical.

Another thing to update is the type of the message objects.

**Before:**

```js
export function consumeIndie(registry) {
  const indie = registry.register({
    name: 'TSLint',
  })

  indie.setMessages([{
    type: 'Error',
    filePath: '/etc/passwd',
    range: [[0, 0], [0, Infinity]],
    text: 'MURICAA! F YEAH!',
  }])
}
```

**After:**

```js
export function consumeIndie(registerIndie) {
  const indie = registerIndie({
    name: 'TSLint',
  })

  indie.setAllMessages([{
    severity: 'error',
    location: {
      file: '/etc/passwd',
      position: [[0, 0], [0, Infinity]]
    },
    excerpt: 'MURICAA! F YEAH!',
  }])
}
```
