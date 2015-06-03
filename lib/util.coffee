path = require 'path'
fs = require 'fs'

findFile = (startDir, name, parent = false, limit = null, aux_dirs = []) ->
  # Find the given file by searching up the file hierarchy from startDir.
  #
  # If the file is found and parent is false, returns the path to the file.
  # If parent is true the path to the file's parent directory is returned.
  #
  # If limit is null or <= 0, the search will continue up to the root directory.
  # Otherwise a maximum of limit directories will be checked.
  #
  # If aux_dirs is not empty and the file hierarchy search failed,
  # those directories are also checked.

  climb = startDir.split(path.sep)
  for item in climb
    dir = climb.join(path.sep) + path.sep

    nameType = {}.toString.call(name)
    if nameType is '[object Array]'
      for n in name
        target = path.join(dir, n)

        if fs.existsSync(target)
          if parent
            return dir
          return target

    if nameType is '[object String]'
      target = path.join(dir, name)

      if fs.existsSync(target)
        if parent
          return dir
        return target

    climb.splice(-1,1)

# TODO: deprecate this export because nothing else can be added to this
# generically-name file without breaking the interface :/
module.exports = findFile
