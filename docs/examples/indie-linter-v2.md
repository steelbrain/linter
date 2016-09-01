# Indie Linter v2

The [Indie Linter API v2](../types/indie-linter-v2.md) demoed below supports [Messages v2](../types/linter-message-v2.md) only.

## package.json

Only the `consumedServices` field is important in this manifest, the rest are
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
  "consumedServices": {
    "linter-indie": {
      "versions": {
        "2.0.0": "consumeIndie"
      }
    }
  }
}
```

## index.js

```js
'use babel'

import { CompositeDisposable } from 'atom'

let subscriptions

export function activate() {
  subscriptions = new CompositeDisposable()
}

export function deactivate() {
  subscriptions.dispose()
}

export function consumeIndie(registerIndie) {
  const linter = registerIndie({
    name: 'Example',
  })
  subscriptions.add(linter)

  // Example using ::setMessages
  subscriptions.add(atom.workspace.observeTextEditors(function(textEditor) {
    const editorPath = textEditor.getPath()
    if (!editorPath) {
      return
    }

    linter.setMessages(editorPath, [{
      severity: 'info',
      location: {
        path: editorPath,
        position: [[0, 0], [0, 1]],
      },
      excerpt: `A random value is ${Math.random()}`,
      description: `### What is this?\nThis is a randomly generated value`
    }])

    const subscription = textEditor.onDidDestroy(function() {
      subscriptions.remove(subscription)
      linter.setMessages(editorPath, [])
    })
    subscriptions.add(subscription)
  })))

  // Example using ::setAllMessages
  linter.setAllMessages([
    {
      severity: 'info',
      location: {
        file: '/tmp/test-1.js',
        position: [[5, 0], [5, 1]],
      },
      excerpt: 'This is an error message on a file',
    },
    {
      severity: 'info',
      location: {
        file: '/tmp/test-3.js',
        position: [[5, 0], [5, 1]],
      },
      excerpt: 'This is an error message on a different file',
    }
  ])
}
```
