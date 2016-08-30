# Indie Linter v2

The Indie Linter demoed below supports [Messages v2](../linter-message-v2.md) only.

## package.json

Only the `consumedServices` field is important in this manifest, the rest are just for reference

```json
{
  "name": "my-indie-linter",
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
/* @flow */

import { CompositeDisposable } from 'atom'

const myLinterPackage = {
  activate() {
    this.subscriptions = new CompositeDisposable()
  },
  deactivate() {
    this.subscriptions.dispose()
  },
  consumeIndie(registry) {
    const linter = registry.register({
      name: 'My Linter',
    })
    this.subscriptions.add(linter)

    // Set messages on every opened file
    this.subscriptions.add(atom.workspace.observeTextEditors(textEditor => {
      const editorPath = textEditor.getPath()
      if (!editorPath) {
        return
      }

      linter.setMessages(editorPath, [{
        severity: 'info',
        location: {
          path: editorPath,
          position: [[0, 0], [0, Infinity]],
        },
        excerpt: `A random value is ${Math.random()}`,
        description: `### What is this?\nThis is a randomly generated value`
      }])

      const subscription = textEditor.onDidDestroy(() => {
        this.subscriptions.remove(subscription)
        linter.setMessages(editorPath, [])
      })
      this.subscriptions.add(subscription)
    })))
  },
}

module.exports = myLinterPackage
```
