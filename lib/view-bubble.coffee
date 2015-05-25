

{View} = require 'space-pen'

class Bubble extends View
  initialize:(LinterView, Message)->
    @append LinterView.messageLine Message
    return unless Message.Trace and Message.Trace.length
    Message.Trace.forEach (Entry)=>
      @append LinterView.messageLine Entry
  @content:->
    @div id: 'linter-inline'
module.exports = Bubble