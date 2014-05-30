{spawn} = require 'child_process'
temp = require 'temp'
fs = require 'fs'

temp.track()

# workaround to get full stdout output in Windows
exec = (command, args = [], options = {}, callback) ->
  readFileOpts = encoding: 'utf-8'

  # TODO use promise to create temp file synchronusly
  temp.open 'exec_out', (err_temp_out, temp_out) ->
    # TODO handle err
    temp.open 'exec_err', (err_temp_err, temp_err) ->
      # TODO handle err

      options.stdio = ['ignore', temp_out.fd, temp_err.fd]

      child = spawn command, args, options
      child.on 'close', (code) ->
        # TODO use promise to close file and read content synchronusly
        fs.close temp_out.fd, () ->
          fs.close temp_err.fd, () ->
            fs.readFile temp_out.path, readFileOpts, (err_stdout, stdout) ->
              # TODO handle err
              fs.readFile temp_err.path, readFileOpts, (err_stderr, stderr) ->
                # TODO handle err
                callback code, stdout, stderr

module.exports = exec
