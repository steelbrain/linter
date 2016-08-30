# UI Provider v1

Linter fills the messages with `version` and `key` keys to make telling difference easy for UI providers.

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
    "linter-ui": {
      "versions": {
        "1.0.0": "consumeUI"
      }
    }
  }
}
```

# index.js

```js
const myUIPackage = {
  activate() {
    // Fill something here, optional
  },
  deactivate() {
    // Fill something here, optional
  },
  consumeUI() {
    return {
      name: 'Sissi - The World Eater',
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
        // Delete any register panels and stuff here
      },
    }
  }
}

module.exports = myUIPackage
```
