'use babel'

import {MessageRegistry} from '../lib/message-registry'
import {getLinter, getMessage} from '../spec/common'
import {timeNow, timeDiff, getMessages} from './common'

const messageRegistry = new MessageRegistry()
messageRegistry.debouncedUpdate = function() {}
const linter = getLinter()

function benchmarkRegistry(i) {
  let timeKey = 'iteration #' + i
  messages = getMessages(5000)
  console.time(timeKey)
  messageRegistry.set({linter, messages, buffer: null})
  messageRegistry.update()
  console.timeEnd(timeKey)
}

for (let i = 0; i < 50; ++i) {
  benchmarkRegistry(i)
}
