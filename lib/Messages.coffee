

class Error
  constructor:(@Message, @File, @Position, @Trace)->
class Warning
  constructor:(@Message, @File, @Position, @Trace)->
module.exports = {Error, Warning}
