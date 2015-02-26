findFile = require './util'

log = (args...) ->
  if atom.config.get 'linter.lintDebug'
    console.log args...

warn = (args...) ->
  if atom.config.get 'linter.lintDebug'
    console.warn args...

# Move cursor to the previous lint message
moveToPreviousMessage = (messages, editor) ->
  cursorLine = editor.getCursorBufferPosition().row + 1
  previousLine = -1
  lastLine = -1
  for {line} in messages ? []
    if line < cursorLine
      previousLine = Math.max(line - 1, previousLine)

    lastLine = Math.max(line - 1, lastLine)

  # Wrap around to the last diff in the file
  previousLine = lastLine if previousLine is -1

  # TODO: when possible, move to the correct column
  moveToLine(editor, previousLine)

# Move cursor to the next lint message
moveToNextMessage = (messages, editor) ->
  cursorLine = editor.getCursorBufferPosition().row + 1
  nextLine = null
  firstLine = null
  for {line} in messages ? []
    if line > cursorLine
      nextLine ?= line - 1
      nextLine = Math.min(line - 1, nextLine)

    firstLine ?= line - 1
    firstLine = Math.min(line - 1, firstLine)

  # Wrap around to the first diff in the file
  nextLine = firstLine unless nextLine?

  # TODO: when possible, move to the correct column
  moveToLine(editor, nextLine)

# Move cursor to the specified line number
moveToLine = (editor, n = -1) ->
  if n >= 0
    editor.setCursorBufferPosition([n, 0])
    editor.moveToFirstCharacterOfLine()

module.exports = {log, warn, findFile, moveToPreviousMessage, moveToNextMessage}
