class LinterTrace
  constructor: (@Message, @File, @Position) ->

class LinterMessage then constructor: (@Message, @File, @Position, @Trace) ->

class LinterError extends LinterMessage

class LinterWarning extends LinterMessage

module.exports = {LinterTrace, LinterMessage, LinterError, LinterWarning}