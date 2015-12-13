'use babel'

import {getMessage} from '../spec/common'

export function timeNow() {
  return process.hrtime()
}

export function timeDiff(last) {
  const diff = process.hrtime(last)
  return Math.round((diff[0] + (diff[1] * 1e-9)) * 1000)
}

export function getMessages(count) {
  const messages = []
  for (let i = 0; i < count; ++i) {
    messages.push(getMessage('Error'))
  }
  return messages
}
