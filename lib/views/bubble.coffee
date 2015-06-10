module.exports = (linter, message) ->
  root = document.createElement 'div'
  root.id = 'linter-inline'
  root.appendChild linter.view.messageLine message, false
  if message.trace and message.trace.length
    message.trace.forEach (trace) ->
      root.appendChild linter.view.messageLine trace
  return root
