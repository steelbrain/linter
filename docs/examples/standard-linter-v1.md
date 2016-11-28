# Standard Linter v1

The [Standard Linter API v1](../types/standard-linter-v1.md) demoed below
supports [Messages v1](../types/linter-message-v1.md) only.

## package.json

Only the `providedServices` field is important in this manifest, the rest are
just for reference.

```json
{
  "name": "linter-example",
  "main": "index.js",
  "version": "0.0.0",
  "private": true,
  "description": "My Linter Package",
  "keywords": ["linter-example", "example"],
  "engines": {
    "atom": ">=1.4.0 <2.0.0"
  },
  "providedServices": {
    "linter": {
      "versions": {
        "1.0.0": "provideLinter"
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

export function provideLinter() {
  return {
    name: 'Example',
    scope: 'file', // or 'project'
    lintsOnChange: false, // or true
    grammarScopes: ['source.js'],
    lint(textEditor) {
      const editorPath = textEditor.getPath()

      // Note, a Promise may be returned as well!
      return [{
        type: 'Error',
        text: 'Something went wrong',
        range: [[0,0], [0,1]],
        filePath: editorPath
      }]
    }
  }
}
```
