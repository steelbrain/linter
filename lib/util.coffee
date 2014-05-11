path = require "path"
fs = require "fs"

# def climb(startDir, limit=null)->
#   """
#   Generate directories, starting from startDir.
#
#   If limit is null or <= 0, stop at the root directory.
#   Otherwise return a maximum of limit directories.
#
#   """
#
#   right = true
#
#   while right and (limit is null or limit > 0):
#     yield startDir
#     startDir, right = startDir.split(path.sep)
#
#     if limit is not null:
#         limit -= 1

#
findFile = (startDir, name, parent=false, limit=null, aux_dirs=[]) ->
  """
  Find the given file by searching up the file hierarchy from startDir.

  If the file is found and parent is false, returns the path to the file.
  If parent is true the path to the file's parent directory is returned.

  If limit is null or <= 0, the search will continue up to the root directory.
  Otherwise a maximum of limit directories will be checked.

  If aux_dirs is not empty and the file hierarchy search failed,
  those directories are also checked.

  """
  climb = startDir.split(path.sep)
  for item in climb
    dir = climb.join(path.sep) + path.sep
    target = path.join(dir, name)

    console.log dir

    if fs.existsSync(target)
      if parent
        return dir
      return target

    climb.splice(-1,1)

  # for d in climb(startDir, limit=limit):
  #   target = os.path.join(d, name)
  #
  #   if os.path.exists(target):
  #     if parent:
  #       return d
  #
  #     return target
#
#     for d in aux_dirs:
#         d = os.path.expanduser(d)
#         target = os.path.join(d, name)
#
#         if os.path.exists(target):
#             if parent:
#                 return d
#
#             return target

module.exports = findFile
