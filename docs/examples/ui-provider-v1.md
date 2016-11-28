# UI Provider v1

This example demonstrates usage of [UI Provider v1 API][]

**Note**: Linter fills the messages with `version` and `key` keys to make
telling the difference between `Message`s easy for UI providers.
**Note**: UI Providers may receive all versions of messages the base linter can
accept.

## package.json

Only the `providedServices` field is important in this manifest, the rest are
just for reference.

```json
{
  "name": "linter-ui-example",
  "main": "index.js",
  "version": "0.0.0",
  "private": true,
  "description": "My Linter UI Package",
  "keywords": ["linter-ui", "example"],
  "engines": {
    "atom": ">=1.4.0 <2.0.0"
  },
  "providedServices": {
    "linter-ui": {
      "versions": {
        "1.0.0": "provideUI"
      }
    }
  }
}
```

## index.js

```js
'use babel'

export function activate() {
  // Fill something here, optional
}

export function deactivate() {
  // Fill something here, optional
}

export function provideUI() {
  return {
    name: 'Example',

    didBeginLinting(linter, filePath) {
      if (filePath === null) {
        console.log('Project scoped linter started', linter.name)
      } else {
        console.log('File scoped linter started', linter.name, 'on', filePath)
      }
    },

    didFinishLinting(linter, filePath) {
      if (filePath === null) {
        console.log('Project scoped linter finished', linter.name)
      } else {
        console.log('File scoped linter finished', linter.name, 'on', filePath)
      }
    },

    render({ added, removed, messages }) {
      console.log('added messages', added.length)
      console.log('removed messages', removed.length)
      console.log('total messages', messages.length)
    },

    dispose() {
      // Delete any registered panels and stuff here
    },
  }
}
```

[UI Provider v1 API]: ../types/ui-provider-v1.md
