# Upcoming

* Fix message render for non TextEditor panes (Fixes #610)

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
