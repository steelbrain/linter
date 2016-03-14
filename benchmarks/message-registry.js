'use babel'

import MessageRegistry from '../lib/message-registry'
import { getLinter, getMessages } from '../spec/common'

const messageRegistry = new MessageRegistry()
messageRegistry.debouncedUpdate = function() {}
const linter = getLinter()

function benchmarkRegistry() {
  const messages = getMessages(5000)
  const start = performance.now()
  messageRegistry.set({ linter, messages, buffer: null })
  messageRegistry.update()
  return performance.now() - start
}
module.exports = function() {
  let sum = 0
  const count = 500
  for (let i = 0; i < count; ++i) {
    sum += benchmarkRegistry()
  }
  console.log('average message registry diff time for 5k messages: ' + (sum / (count - 1)))
}
