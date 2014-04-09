Linter = require './linter'

class LinterPhpcs extends Linter
  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ['text.html.php', 'source.php']

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: '/usr/local/php5/bin/phpcs --report=checkstyle'

  # A regex pattern used to extract information from the executable's output.
  regex: '.*line="(?<line>[0-9]+)" column="(?<col>[0-9]+)" severity="((?<error>error)|(?<warning>warning))" message="(?<message>.*)" source'

module.exports = LinterPhpcs