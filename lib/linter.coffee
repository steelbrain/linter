Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'

{LinterTrace, LinterMessage, LinterError, LinterWarning} = require './messages'

class Linter
  constructor: ->
    @Emitter = new Emitter
    @SubRegular = new CompositeDisposable
    @SubFly = new CompositeDisposable
