# Standard Linter v2

The Standard Linter demoed below supports [Messages v2](../types/linter-message-v2.md) only.

## package.json

Only the `providedServices` field is important in this manifest, the rest are just for reference

```json
{
  "name": "my-linter",
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
  const linterProvider = {
    scope: 'file', // or 'project'
    lintOnFly: true, // or false
    grammarScopes: ['source.js'],
    lint(textEditor) {
      const editorPath = textEditor.getPath()

      // Do something sync and
      return [{
        severity: 'info',
        location: {
          path: editorPath,
          position: [[0, 0], [0, Infinity]],
        },
        excerpt: `A random value is ${Math.random()}`,
        description: `### What is this?\nThis is a randomly generated value`
      }]

      // Do something async
      return new Promise(function(resolve) {
        resolve([{
          severity: 'info',
          location: {
            path: editorPath,
            position: [[0, 0], [0, Infinity]],
          },
          excerpt: `A random value is ${Math.random()}`,
          description: `### What is this?\nThis is a randomly generated value`
        }])
      })
    }
  }
  return linterProvider
}
```
