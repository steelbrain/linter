'use babel'

import { getMessage } from '../spec/common' // eslint-disable-line

export function getMessages(count) {
  const messages = []
  for (let i = 0; i < count; ++i) {
    messages.push(getMessage('Error'))
  }
  return messages
}
