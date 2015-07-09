# 1.2.3

* Fix a bug where panel won't be hidden even with no errors.

# 1.2.2

* Fix a bug where count wont be updated on render.

# 1.2.1

* Fix a bug with legacy Linter API

# 1.2.0

* Fix a bug when Error Panel won't collapse even when there's no errors with File as Active Tab
* Speed Improvements
* Remove the "Default Error Tab" config option in favor of storing the currently selected tab in the package state.
* Fix a bug where require time errors of legacy API providers would be shown as linter errors
* Tweak the status line item positioning
* Add Helpers which aid the creation of Command Line Linters.
* Add `linter:togglePanel` command to toggle bottom panel
* Add `linter.ignoredMessageTypes` config to ignore certain message types

# 1.1.0

* Add support for collapsible messages
* Add tab `Line` to show only errors of the current line.
* Add config options to hide individual tabs (`Line`, `File`, `Project`).

# 1.0.9

* Add some default keybindings (Fixes #597)
* Fix a bug where changing project paths won't trigger Linters (Fixes #622)
* UI is rendered when Messages are changed programatically (Fixes #639)
* Make the position of bottom status icon configurable
* Fix a bug where disabling underline would also disable gutter indicator

# 1.0.8

* Fix a critical error in self service provider

# 1.0.7

* Rename the status line summary (from `Errors` to `Issues`)
* Rename the `Current File` tab to just `File`
* Move the `No Issues` badge to the right side of the bottom bar
* Fix a bug where a message containing HTMLElement would do weird things
* Allow Issue underlining to be configured from settings

# 1.0.6

* Hide Status Bar buttons when Active Pane is not an editor

# 1.0.5

* Fix message render for non TextEditor panes (Fixes #610)
* Make the bubble follow cursor
* Show a nicer error if linter binary doesn't exist (Fixes #612)
* Add set-bubble-transparent command to set the bubble transparent until the key is released (Fixes #608)
* Deselect bottom tab when error panel is hidden
* Add linter:lint command (Fixes #624)

# 1.0.4

* Fix a critical bug introduced by 1.0.3

# 1.0.3

* Treat legacy messages as text instead of html
* Fix a bug causing linter messages to briefly disappear and reappear
* Fix memory leak (Markers weren't getting cleaned up)
* Use the same filename as the source when generating a temporary file (Fixes #585)

# 1.0.2

* Lint requests are now ignored until the file is saved
* Allow the user to hide bottom panel from settings or by clicking active tab
* Add linter:next-error command to jump to next error in code
* Allow jump to next error by clicking the bottom status icon
* Add linter:toggle command to disable linting for current text editor temporarily

# 1.0.1

* Fix a compatibility issue: linters were only linting what was on disk.

# 1.0.0

* Complete rewrite
