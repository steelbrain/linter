module.exports = (Linter, Message) ->
  Root = document.createElement 'div'
  Root.id = 'linter-inline'
  Root.appendChild Linter.View.messageLine Message, false
  if Message.Trace and Message.Trace.length
    Message.Trace.forEach (Trace) ->
      Root.appendChild Linter.View.messageLine Trace
  return Root