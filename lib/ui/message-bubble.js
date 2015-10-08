'use babel'

import {Message} from './message-element'

export function create(message) {
  const bubble = document.createElement('div')
  bubble.id = 'linter-inline'
  bubble.appendChild(Message.fromMessage(message, false))
  if (message.trace && message.trace.length) {
    message.trace.forEach(function(trace) {
      bubble.appendChild(Message.fromMessage(trace).updateVisibility('Project'))
    })
  }
  return bubble
}
