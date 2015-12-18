'use babel'

import MessageRegistry from '../lib/message-registry'
import {getLinter, getMessage} from '../spec/common'
import {timeNow, timeDiff, getMessages} from './common'

const messageRegistry = new MessageRegistry()
messageRegistry.active = false // Disable the auto-updater
messageRegistry.shouldRefresh = false // Disable the auto-updater
const linter = getLinter()

let time = null
let messages = null

function benchmarkRegistry(i) {
  messages = getMessages(5000)
  time = timeNow()

  messageRegistry.set({linter, messages})
  if (messageRegistry.updatePublic) {
    messageRegistry.updatePublic()
  } else if (messageRegistry.processQueue) {
    messageRegistry.processQueue()
  }
  const diff = timeDiff(time)
  console.log('iteration #', i,'took', diff, 'ms')
  return diff
}

let promise = Promise.resolve()
let sum = 0
let count = 1000

for (let i = 0; i < count; ++i) {
  promise = promise.then(function() {
    sum += benchmarkRegistry(i)
  })
}
promise.then(function() {
  console.log('average', sum / count)
})
