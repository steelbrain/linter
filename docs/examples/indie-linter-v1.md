# Indie Linter v1

The [Indie Linter API v1](../types/indie-linter-v1.md) demoed below supports [Messages v1](../types/linter-message-v1.md) only.

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
        "1.0.0": "consumeLinter"
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

export function consumeLinter(indieRegistry) {
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
      type: 'Error',
      text: 'Something went wrong'
    }])

    const subscription = textEditor.onDidDestroy(function() {
      subscriptions.remove(subscription)
      linter.setMessages(editorPath, [])
    })
    subscriptions.add(subscription)
  }))
}
```
