### 3.4.0

- feat: allow solutions to be an async callback
- fix: add a warning when a provider is in the list of disabled providers
- Update dependencies
- other bug fixes

### 3.3.1

- fix: update dependencies #1729
  fix: the issue with atom-package-deps not installing the linter dependency #1729
- minor optimizations #1729

### 3.3.0

- Fix subfolder git detection (#1715):
  if you add a project folder which is not a git repo but it contains folders which are git repos, then the repository detection now works correctly. The `repositoryForDirectory` function in `atom.project` is able to detect the repository for any Directory, even if it is in a subfolder.
  It is an async function, so some changes have to be made in up the call chain

### 3.2.3

- Minor optimizations

### 3.2.2

- Use class props and merge subscriptions.add (#1720)

### 3.2.1

- Use strict-null check in TypeScript and fix some bugs (#1719)

### 3.2.0

- Convert the codebase to TypeScript (#1718)

### 3.1.1

- Minor optimizations

## 3.1.0

- Now linter loads 13 times faster! (#1695)

## 3.0.0

- Improve performance (#1706)
- Rewrite diff check algorithm (#1706)
- Fix linter fixes (#1706)

In case you maintain a linter-ui packages (e.g. linter-ui-default, linter-minimap), see this guide for upgrading: https://github.com/steelbrain/linter/blob/master/docs/guides/upgrading-to-linter-v3.md

## 2.3.1

- Upgrade dependencies to fix vulns

## 2.3.0

- Remove support for legacy linter APIs
- Add a button to open developer console on Linter error messages
- Include `description` in message key (when string rather than promise)
- Fix a bug where linter messages (file-scoped) would disappear when same buffer is opened in two editors and one of them is closed

## 2.2.0

- `linter:debug` overhaul with more debug information
- Add `linterName` support to messages API v2 (Thanks @hansonw from Facebook)

## 2.1.4

- Hotfix release for a regression introduced in last version (sorry everyone)

## 2.1.3

- Add `disabledProviders` config that tracks the list of disabled linter providers
- Enhance linter provider error message to include opening instructions for dev tools

## 2.1.2

- Hotfix release for a regression introduced in last version

## 2.1.1

- Unset no longer available v1 configs
- Make `linter.name` optional for v1 again
- Do not show Linter v2 for greeter for new installations
- Fix a bug where disabling and reenabling `linter-ui-default` would not add previously existent issues to the UI

## 2.1.0

- Add support for Legacy Indie Providers v1
- Move docs to GitHub pages, docs can now be found at [`steelbrain.me/linter`](http://steelbrain.me/linter)

## 2.0.0

- Rewrite entire package
- Add support for Linter Messages v2
- Add support for Indie Providers v2
- Drop support for Indie Providers v1

## Pre v2.0

See the CHANGELOG for Pre v2.0 at [v1 CHANGELOG](https://github.com/steelbrain/linter/blob/v1/CHANGELOG.md)
