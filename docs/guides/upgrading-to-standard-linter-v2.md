# Upgrading to Standard Linter v2

This upgrade guide assumes your package current implements [Standard Linter API v1](https://github.com/steelbrain/linter/wiki/Linter-API) and [Message API v1](https://github.com/steelbrain/linter/wiki/Linter-API#messages).

## package.json

You need to update the version in the manifest for `linter` service from `1.x.x` to `2.0.0`.

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

In the newer version, the `name` property is now mandatory. Providers must also return Message v2 instead of Message v1.

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
    lintOnFly: false,
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
