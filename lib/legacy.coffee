fs = require('fs')
temp = require('temp')

typeMap =
  info: 'Trace'
  warning: 'Warning'
  error: 'Error'

transform = (filePath, textEditor, results) ->
  results.map(({message, level, range}) ->
    [ [startLine, startCol], [ endLine, endCol ] ] = (range.serialize?() ? range)

    msg =  {
      # If the type is non-standard just pass along whatever it was
      type: typeMap[level] ? level
      html: message
      filePath: filePath
      range: [
        [ startLine, startCol],
        [ endLine, endCol]
      ]
    }

    return msg
  )

module.exports = (ClassicLinter) ->

  editorMap = new WeakMap()
  grammarScopes = ClassicLinter.syntax
  unless grammarScopes instanceof Array
    grammarScopes = [ grammarScopes ]

  return {
    grammarScopes
    scope: 'file'
    lintOnFly: true

    lint: (textEditor) ->

      # Try to reuse the same instance if we can.
      linter = editorMap.get(textEditor)
      unless linter
        linter = new ClassicLinter(textEditor)
        editorMap.set(textEditor, linter)

      filePath = textEditor.getPath()

      tmpOptions = {
        prefix: 'AtomLinter'
        suffix: textEditor.getGrammar().scopeName
      }
      return new Promise((resolve, reject) ->
        temp.open(tmpOptions, (err, info) ->
          return reject(err) if err

          fs.write(info.fd, textEditor.getText())
          fs.close(info.fd, (err) ->
            return reject(err) if err
            linter.lintFile(info.path, (results) ->
              fs.unlink(info.path)

              resolve(transform(filePath, textEditor, results))
            )
          )
        )
      )
  }
