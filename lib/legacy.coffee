fs = require('fs')
path = require('path')
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
      text: message
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
        temp.mkdir('AtomLinter', (err, tmpDir) ->
          return reject(err) if err

          try
            tmpFile = path.join(tmpDir, path.basename(filePath))
            fs.writeFileSync(tmpFile, textEditor.getText())

            linter.lintFile(tmpFile, (results) ->
              # fs.rmdir only works on empty directories, so we have to delete
              # the file first
              fs.unlink(tmpFile)
              fs.rmdir(tmpDir)

              resolve(transform(filePath, textEditor, results))
            )
          catch error
            reject(error)
        )
      )
  }
