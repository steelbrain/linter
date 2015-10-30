## 1.10.0

* Fix a minor style issue in bottom tabs
* Add a new `displayLinterStatus` config

## 1.9.1

* Add `ignoreMatchedFiles` config
* Fix an issue where the `linter.displayLinterInfo` preference was not respected

## 1.9.0

* Fix compatibility with upcoming version of atom
* Support for buffer modifying linters has been removed (We don't think anybody was using them anyway)
* Add a new `inlineTooltipInterval` config
* Major speed improvements
* Make ctrl-c work on bottom panel
* Fix certain scenarios where inline bubbles would be placed incorrectly (Bubbles no longer follow the cursor, they re-use markers from underlines)
* Add a new `lintOnFlyInterval` config
* Messages of a single editor are now shown together
* Add a new `ignoreVCSIgnoredFiles` config

## 1.8.1

* Workaround an atom bug where moving an editor between panes would throw an error
* Allow panel resize to persist
* Add option to always have the panel to fill the minimum space
* Fix issue where external scope errors would cause panel to continue displaying

## 1.8.0

* Improve rendering of multiline messages to align with recent single line changes
* Enable clicking on multiline messages to view next lines
* Add default styles for `Info` type
* Aligned bottom panel buttons
* Made the text in the bottom panel selectable
* Linter bottom panel is now resizable (Drag the height down to 0 to reset your changes)
* Add a new `class` attribute for provider messages (when class is provided, no class is automatically added).
* Fix linter gutter dot alignment across themes and zoom level.

## 1.7.2

* Fixed links for multiline messages

## 1.7.1

* Fix a crash that would happen if message has a filePath but doesn't have a link in DOM

## 1.7.0

* Add `showProviderName` config
* Deprecated self-APIs `Linter::{onDidChangeMessages, onDidChangeProjectMessages, getProjectMessages, setProjectMessages, deleteProjectMessages}` have been removed
* Add new `gutterEnabled` and `gutterPosition` configurations
* Removed EditorLinter::destroy in favor of EditorLinter::dispose
* `.icon-right::before` css selector has been replaced by `.linter-gutter` of the new linter gutter element.
* Added `onDidMessage{Add, Remove, Delete}` listeners on EditorLinter for self-api consumers
* Added EditorLinter::getMessages API for getting messages specific to that editor linter.
* Linter now supports decorating multiple panes at the same time. Decorations are no longer removed and re-added on tab changed, only added to the new tab. Which could improve the tab switch performance with large errors.
* Multiline messages render correctly by allowing overflow and using flexbox to enable single line output of the location.
* Remove location from bubble information.

## 1.6.0

* Fixed messages so that they line up and don't wrap in weird ways (Fixes #859)
* Lint is toggled everytime you toggle enable linter

## 1.5.2

* Add `displayLinterInfo` config to toggle visibility of bottom panel

## 1.5.1

* Messages are now tracked on a per-buffer basis rather than per-editor,
  improving the multi-pane experience by eliminating the potential for stale
  results.
* Fix extra padding in panel when there's no messages

## 1.5.0

* Fix baseline alignment of text on the bottom bar
* Fix a bug where linter:togglePanel won't work
* Stricter message validation, helps catching provider bugs

## 1.4.3

* Fix a bug where bottom tabs's count won't be updated on pane change unless lint is triggered
* Fix a bug where paths would be shown at first even when file tab is selected.

## 1.4.2

* Re-add `statusIconPosition` config
* Fix a typo in Linter:toggle

## 1.4.1

* Fix a critical typo

## 1.4.0

* Fix a bug where clicking non-active bottom container tab wouldn't enable bottom panel (Fixes #830)
* Fix a bug where markers from files not opened at linting time won't work (only applies to Project-scoped-linters)
* Introduce an extremely efficient bottom panel (bubble is the only performance bottleneck now)

## 1.3.4

* Messages are now deleted when a linter provider is deleted/deactivated.

## 1.3.3

* Fix linter-panel's `overflow-y` to only display the scrollbar when necessary.
* Fix some error cases where markers won't be destroyed properly.

## 1.3.2

* Increase messages refresh interval, which should result in a cpu load decrease

## 1.3.1

* Fix a critical typo affecting multi line messages

## 1.3.0

* Fix a bug where messages would be updated for a lazy linter after text editor has closed and there is no way to make them disappear
* Fix a bug where linter:toggle won't clear errors
* Fix a bug where linter:lint won't update the bottom status icon count
* Add statusIconScope configuration
* Fix a bug where panel won't be toggled if you click the bottom tab twice
* Fix a bug where stringish errors from providers won't be handled properly
* Fix several typos
* Add efficient marker updates mechanism (:racehorse:)
* Lots of cleanups and re-organization
* Add a bunch of new Events for self-api consumers
* :fire: Remove support for legacy providers completely!
* :art: Fix wrapping of issue messages
* Remove `alt` keybindings to avoid conflict with core's
* Add contribution guidelines
* Fixed a marker leak with bubbles, which would make editor slower over time.
* Remove an oudated config (`statusIconPosition`).
* Invalidate Range when a range is removed from buffer.

## 1.2.3

* Fix a bug where panel won't be hidden even with no errors.

## 1.2.2

* Fix a bug where count wont be updated on render.

## 1.2.1

* Fix a bug with legacy Linter API

## 1.2.0

* Fix a bug when Error Panel won't collapse even when there's no errors with File as Active Tab
* Speed Improvements
* Remove the "Default Error Tab" config option in favor of storing the currently selected tab in the package state.
* Fix a bug where require time errors of legacy API providers would be shown as linter errors
* Tweak the status line item positioning
* Add Helpers which aid the creation of Command Line Linters.
* Add `linter:togglePanel` command to toggle bottom panel
* Add `linter.ignoredMessageTypes` config to ignore certain message types

## 1.1.0

* Add support for collapsible messages
* Add tab `Line` to show only errors of the current line.
* Add config options to hide individual tabs (`Line`, `File`, `Project`).

## 1.0.9

* Add some default keybindings (Fixes #597)
* Fix a bug where changing project paths won't trigger Linters (Fixes #622)
* UI is rendered when Messages are changed programatically (Fixes #639)
* Make the position of bottom status icon configurable
* Fix a bug where disabling underline would also disable gutter indicator

## 1.0.8

* Fix a critical error in self service provider

## 1.0.7

* Rename the status line summary (from `Errors` to `Issues`)
* Rename the `Current File` tab to just `File`
* Move the `No Issues` badge to the right side of the bottom bar
* Fix a bug where a message containing HTMLElement would do weird things
* Allow Issue underlining to be configured from settings

## 1.0.6

* Hide Status Bar buttons when Active Pane is not an editor

## 1.0.5

* Fix message render for non TextEditor panes (Fixes #610)
* Make the bubble follow cursor
* Show a nicer error if linter binary doesn't exist (Fixes #612)
* Add set-bubble-transparent command to set the bubble transparent until the key is released (Fixes #608)
* Deselect bottom tab when error panel is hidden
* Add linter:lint command (Fixes #624)

## 1.0.4

* Fix a critical bug introduced by 1.0.3

## 1.0.3

* Treat legacy messages as text instead of html
* Fix a bug causing linter messages to briefly disappear and reappear
* Fix memory leak (Markers weren't getting cleaned up)
* Use the same filename as the source when generating a temporary file (Fixes #585)

## 1.0.2

* Lint requests are now ignored until the file is saved
* Allow the user to hide bottom panel from settings or by clicking active tab
* Add linter:next-error command to jump to next error in code
* Allow jump to next error by clicking the bottom status icon
* Add linter:toggle command to disable linting for current text editor temporarily

## 1.0.1

* Fix a compatibility issue: linters were only linting what was on disk.

## 1.0.0

* Complete rewrite
