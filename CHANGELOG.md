## 2.2.0

* `linter:debug` overhaul with more debug information
* Add `linterName` support to messages API v2 (Thanks @hansonw from Facebook)

## 2.1.4

* Hotfix release for a regression introduced in last version (sorry everyone)

## 2.1.3

* Add `disabledProviders` config that tracks the list of disabled linter providers
* Enhance linter provider error message to include opening instructions for dev tools

## 2.1.2

* Hotfix release for a regression introduced in last version

## 2.1.1

* Unset no longer available v1 configs
* Make `linter.name` optional for v1 again
* Do not show Linter v2 for greeter for new installations
* Fix a bug where disabling and reenabling `linter-ui-default` would not add previously existent issues to the UI

## 2.1.0

* Add support for Legacy Indie Providers v1
* Move docs to GitHub pages, docs can now be found at [`steelbrain.me/linter`](http://steelbrain.me/linter)

## 2.0.0

* Rewrite entire package
* Add support for Linter Messages v2
* Add support for Indie Providers v2
* Drop support for Indie Providers v1

## Pre v2.0

See the CHANGELOG for Pre v2.0 at [v1 CHANGELOG](https://github.com/steelbrain/linter/blob/v1/CHANGELOG.md)
