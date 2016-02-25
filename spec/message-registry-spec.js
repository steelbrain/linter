'use babel'

import {MessageRegistry} from '../lib/message-registry'

describe('Message Registry', function() {
  function getMessage() {
    return {type: 'text', filePath: '/tmp/passwd', range: [[0, 1], [1, 0]], text: String(Math.random())}
  }
  function getLinter(name) {
    return {name}
  }

  let messageRegistry
  beforeEach(function() {
    messageRegistry = new MessageRegistry()
    messageRegistry.debouncedUpdate = jasmine.createSpy('debouncedUpdate')
  })
  afterEach(function() {
    messageRegistry.dispose()
  })

  describe('::set', function() {
    fit('stores results using both buffer and linter', function() {
      const messageFirst = getMessage()
      const messageSecond = getMessage()
      const messageThird = getMessage()
      const linter = getLinter('any')
      const buffer = {}
      let info

      messageRegistry.set({linter, buffer: null, messages: [messageFirst]})
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(1)
      expect(messageRegistry.messagesMap.size).toBe(1)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.oldMessages.length).toBe(0)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      messageRegistry.set({linter, buffer: null, messages: [messageFirst]})
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(2)
      expect(messageRegistry.messagesMap.size).toBe(1)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.oldMessages.length).toBe(1)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      messageRegistry.set({linter, buffer, messages: [messageThird]})
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(3)
      expect(messageRegistry.messagesMap.size).toBe(2)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.oldMessages.length).toBe(1)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      info = [...messageRegistry.messagesMap][1]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(buffer)
      expect(info.oldMessages.length).toBe(0)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageThird)

      messageRegistry.set({linter, buffer: null, messages: [messageFirst, messageSecond]})
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(4)
      expect(messageRegistry.messagesMap.size).toBe(2)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.oldMessages.length).toBe(1)
      expect(info.messages.length).toBe(2)
      expect(info.messages[0]).toBe(messageFirst)
      expect(info.messages[1]).toBe(messageSecond)

      info = [...messageRegistry.messagesMap][1]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(buffer)
      expect(info.oldMessages.length).toBe(0)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageThird)
    })
  })
})
