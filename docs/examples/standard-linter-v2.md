# Standard Linter v2

The [Standard Linter API v2][] demoed below supports [Messages v2][] only.

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
        "2.0.0": "provideLinter"
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

      // Do something sync
      return [{
        severity: 'info',
        location: {
          file: editorPath,
          position: [[0, 0], [0, 1]],
        },
        excerpt: `A random value is ${Math.random()}`,
        description: `### What is this?\nThis is a randomly generated value`
      }]

      // Do something async
      return new Promise(function(resolve) {
        resolve([{
          severity: 'info',
          location: {
            file: editorPath,
            position: [[0, 0], [0, 1]],
          },
          excerpt: `A random value is ${Math.random()}`,
          description: `### What is this?\nThis is a randomly generated value`
        }])
      })
    }
  }
}
```

[Standard Linter API v2]: ../types/standard-linter-v2.md
[Messages v2]: ../types/linter-message-v2.md
