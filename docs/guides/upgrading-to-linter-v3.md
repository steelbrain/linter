### Upgrading to Linter V3

:warning: this guide is only for the linter-ui packages (e.g. linter-ui-default, linter-minimap, etc). Linter 3 would continue to work with all the linter clients and ide packages. :warning:

In linter v3, the messages are flagged as `removed` and `added`. `messages` includes all the old "kept" messages plus new "added" messages. That means it is the responsibility of the linter-ui package to delete/add ui elements based on `removed` and `added`.

You should use a `Map` of `message.key` to `message` to store the messages in your cache and update the cache on each cycle based on the key. A `Set` of `message`s will not work.

See [minimap-linter](https://github.com/AtomLinter/atom-minimap-linter/pull/82) for an example of the changes.
