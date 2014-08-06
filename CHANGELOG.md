# v0.5.3

### New Linters
* [linter-jsxhint](https://atom.io/packages/linter-jsxhint), for JSX (React.js), using `jsxhint`

# v0.5.2

### Bug Fixes
* Only widen the gutter when showGutter is enabled ([#137](https://github.com/AtomLinter/Linter/issues/137))
* Delete some unused imports ([#154](https://github.com/AtomLinter/Linter/issues/154))

# v0.5.1

### New Features
* Add keybinding to trigger linting manually ([#146](https://github.com/AtomLinter/Linter/issues/146))

# v0.5.0

### Bug Fixes
* Fix when line is deleted before it can be [hightlig…](https://github.com/AtomLinter/Linter/commit/01786d4ec4cc6a946bf09e4024e22b0dfad858c6)
* fix typo [(showHightlighting -> showHighlighting)](https://github.com/AtomLinter/Linter/commit/e06ad53bca201b108d5743b7966f8fad5050c74b)

### New Features
* Add `@formatMessage` to help any linter to customize message. ([#120](https://github.com/AtomLinter/Linter/pull/120))
* Use decorations API to display gutter markers ([#147](https://github.com/AtomLinter/Linter/pull/147))
* Better way to assemble path ([#142]https://github.com/AtomLinter/Linter/pull/142)

# v0.4.11

### Bug Fixes

* Fix `getBufferPosition` bug ([#99](https://github.com/AtomLinter/Linter/issues/99))
* Don't block UI more than 5s
* Fix bug when running specs
* Fix bug when full line error ([#103](https://github.com/AtomLinter/Linter/pull/103))

# v0.4.10
---------

### Bug Fixes

* Fix bug when linter provides 0 length range
* Fix a bug when special characters appeared in command ([#81](https://github.com/AtomLinter/Linter/pull/81))
* Update `temp` package

# v0.4.9
--------

### New Features
* Show error line and column if available in the status bar
* Lint on focus ([#77](https://github.com/AtomLinter/Linter/pull/77))
* Clicking error message copies it to clipboard ([#78](https://github.com/AtomLinter/Linter/issues/78))

### Bug Fixes
* Fix the error range construction and line reporting for line zero errors ([#35](https://github.com/AtomLinter/Linter/issues/35))
* Fix modify interval config ([#64](https://github.com/AtomLinter/Linter/issues/64))
* Close status bar on file close ([#74](https://github.com/AtomLinter/Linter/pull/74))
* Fix double error reporting in status bar ([#79](https://github.com/AtomLinter/Linter/pull/79))

### New Linters
* [linter-scalac](https://atom.io/packages/linter-scalac), for Scala, using `scalac`


# v0.4.8 (May 26, 2014)
-----------------------

### Bug Fixes
* Lint on save wasn't triggered with save menu shortcut ([#40](https://github.com/AtomLinter/Linter/issues/40))
* Not displaying results if cursor on EOF ([#50](https://github.com/AtomLinter/Linter/issues/50))
* Previous highlights weren't cleared

### Performance Improvements
* Wait 1000ms between two lint on changes ([#32](https://github.com/AtomLinter/Linter/issues/32))

### New Linters
* [linter-pylint](https://atom.io/packages/linter-pylint), for Python, using `pylint`
