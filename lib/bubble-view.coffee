module.exports = (linter, message) ->
  root = document.createElement 'div'
  root.id = 'linter-inline'
  root.appendChild linter.view.messageLine message, false
  if message.Trace and message.Trace.length
    message.Trace.forEach (trace) ->
      root.appendChild linter.view.messageLine trace
  return root
