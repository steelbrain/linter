fs = require('fs')
path = require('path')
temp = require('temp')

promiseWrap = (obj, methodName) ->
  return (args...) ->
    return new Promise((resolve, reject) ->
      obj[methodName](args..., (err, result) ->
        return reject(err) if err
        resolve(result)
      )
    )

mkdir = promiseWrap(temp, 'mkdir')
writeFile = promiseWrap(fs, 'writeFile')
unlink = promiseWrap(fs, 'unlink')

typeMap =
  info: 'Trace'
  warning: 'Warning'
  error: 'Error'

transform = (filePath, textEditor, results) ->
  return [] unless results
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

      lintFile = (filename) ->
        dfd = Promise.defer()
        linter.lintFile(filename, dfd.resolve)
        return dfd.promise

      filePath = textEditor.getPath()

      tmpOptions = {
        prefix: 'AtomLinter'
        suffix: textEditor.getGrammar().scopeName
      }

      return mkdir('AtomLinter').then((tmpDir) ->
        tmpFile = path.join(tmpDir, path.basename(filePath))

        writeFile(tmpFile, textEditor.getText()).then(->
          lintFile(tmpFile).then((results) ->

            # If either of these fail it'll just leave temporary files. No
            # need to reject the promise over it
            unlink(tmpFile).then(-> fs.rmdir(tmpDir))

            return transform(filePath, textEditor, results)
          )
        )
      )
  }
