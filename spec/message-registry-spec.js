'use babel'

import MessageRegistry from '../lib/message-registry'

describe('Message Registry', function() {
  function getMessage() {
    return { type: 'Error', filePath: '/tmp/passwd', range: [[0, 1], [1, 0]], text: String(Math.random()) }
  }
  function getLinter(name) {
    return { name }
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
    it('stores results using both buffer and linter', function() {
      const messageFirst = getMessage()
      const messageSecond = getMessage()
      const messageThird = getMessage()
      const linter = getLinter('any')
      const buffer = {}
      let info

      messageRegistry.set({ linter, buffer: null, messages: [messageFirst] })
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(1)
      expect(messageRegistry.messagesMap.size).toBe(1)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.oldMessages.length).toBe(0)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      messageRegistry.set({ linter, buffer: null, messages: [messageFirst] })
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(2)
      expect(messageRegistry.messagesMap.size).toBe(1)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      messageRegistry.set({ linter, buffer, messages: [messageThird] })
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(3)
      expect(messageRegistry.messagesMap.size).toBe(2)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      info = [...messageRegistry.messagesMap][1]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(buffer)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageThird)

      messageRegistry.set({ linter, buffer: null, messages: [messageFirst, messageSecond] })
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(4)
      expect(messageRegistry.messagesMap.size).toBe(2)
      info = [...messageRegistry.messagesMap][0]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.messages.length).toBe(2)
      expect(info.messages[0]).toBe(messageFirst)
      expect(info.messages[1]).toBe(messageSecond)

      info = [...messageRegistry.messagesMap][1]

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(buffer)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageThird)
    })
  })

  describe('updates (::update & ::onDidUpdateMessages)', function() {
    it('notifies on changes', function() {
      let called = 0
      const message = getMessage()
      messageRegistry.onDidUpdateMessages(function({ added, removed, messages }) {
        called++
        expect(added.length).toBe(1)
        expect(removed.length).toBe(0)
        expect(messages.length).toBe(1)
        expect(added).toEqual(messages)
        expect(added[0]).toBe(message)
      })
      messageRegistry.set({ linter: {}, buffer: null, messages: [message] })
      messageRegistry.update()
      expect(called).toBe(1)
    })
    it('notifies properly for as many linters as you want', function() {
      const buffer = {}
      const linterFirst = getLinter('named')
      const linterSecond = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()
      const messageThird = getMessage()
      let called = 0

      messageRegistry.onDidUpdateMessages(function({ added, removed, messages }) {
        called++

        if (called === 1) {
          expect(added.length).toBe(1)
          expect(removed.length).toBe(0)
          expect(added).toEqual(messages)
          expect(added[0]).toEqual(messageFirst)
          expect(added[0].name).toEqual('named')
        } else if (called === 2) {
          expect(added.length).toBe(2)
          expect(removed.length).toBe(0)
          expect(messages.length).toBe(3)
          expect(messages[0]).toBe(messageFirst)
          expect(messages[1]).toBe(messageSecond)
          expect(messages[2]).toBe(messageThird)
        } else if (called === 3) {
          expect(added.length).toBe(0)
          expect(removed.length).toBe(1)
          expect(removed[0]).toBe(messageFirst)
          expect(messages.length).toBe(2)
          expect(messages[0]).toBe(messageSecond)
          expect(messages[1]).toBe(messageThird)
        } else if (called === 4) {
          expect(added.length).toBe(0)
          expect(removed.length).toBe(2)
          expect(messages.length).toBe(0)
          expect(removed[0]).toBe(messageSecond)
          expect(removed[1]).toBe(messageThird)
        } else {
          throw new Error('Unnecessary update call')
        }
      })

      messageRegistry.set({ buffer, linter: linterFirst, messages: [messageFirst] })
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(1)
      messageRegistry.set({ buffer, linter: linterSecond, messages: [messageSecond, messageThird] })
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(2)
      messageRegistry.set({ buffer, linter: linterFirst, messages: [] })
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(3)
      messageRegistry.set({ buffer, linter: linterSecond, messages: [] })
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(4)
    })

    it('sets key on messages', function() {
      const linter = {}
      const buffer = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()
      const messageThird = getMessage()

      let called = 0

      messageRegistry.onDidUpdateMessages(function({ added, removed, messages }) {
        called++
        if (called === 1) {
          // All messages are new
          expect(added.length).toBe(2)
          expect(removed.length).toBe(0)
          expect(messages.length).toBe(2)
          expect(added).toEqual(messages)
          expect(typeof messages[0].key).toBe('string')
          expect(typeof messages[1].key).toBe('string')
        } else {
          // One removed, one added
          expect(added.length).toBe(1)
          expect(removed.length).toBe(1)
          expect(messages.length).toBe(2)
          expect(messages.indexOf(added[0])).not.toBe(-1)
          expect(typeof messages[0].key).toBe('string')
          expect(typeof messages[1].key).toBe('string')
        }
      })

      messageRegistry.set({ buffer, linter, messages: [messageFirst, messageSecond] })
      messageRegistry.update()
      messageRegistry.set({ buffer, linter, messages: [messageFirst, messageThird] })
      messageRegistry.update()
      expect(called).toBe(2)
    })
  })

  describe('::deleteByBuffer', function() {
    it('deletes the messages and sends them in an event', function() {
      const linter = {}
      const buffer = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()

      let called = 0

      messageRegistry.onDidUpdateMessages(function({ added, removed, messages }) {
        called++
        if (called === 1) {
          expect(added.length).toBe(2)
          expect(removed.length).toBe(0)
          expect(messages.length).toBe(2)
          expect(added).toEqual(messages)
          expect(added[0]).toBe(messageFirst)
          expect(added[1]).toBe(messageSecond)
        } else if (called === 2) {
          expect(added.length).toBe(0)
          expect(removed.length).toBe(2)
          expect(messages.length).toBe(0)
          expect(removed[0]).toBe(messageFirst)
          expect(removed[1]).toBe(messageSecond)
        } else {
          throw new Error('Unnecessary update call')
        }
      })
      messageRegistry.set({ buffer, linter, messages: [messageFirst, messageSecond] })
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(1)
      messageRegistry.deleteByBuffer(buffer)
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(2)
    })
  })

  describe('::deleteByLinter', function() {
    it('deletes the messages and sends them in an event', function() {
      const linter = {}
      const buffer = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()

      let called = 0

      messageRegistry.onDidUpdateMessages(function({ added, removed, messages }) {
        called++
        if (called === 1) {
          expect(added.length).toBe(2)
          expect(removed.length).toBe(0)
          expect(messages.length).toBe(2)
          expect(added).toEqual(messages)
          expect(added[0]).toBe(messageFirst)
          expect(added[1]).toBe(messageSecond)
        } else if (called === 2) {
          expect(added.length).toBe(0)
          expect(removed.length).toBe(2)
          expect(messages.length).toBe(0)
          expect(removed[0]).toBe(messageFirst)
          expect(removed[1]).toBe(messageSecond)
        } else {
          throw new Error('Unnecessary update call')
        }
      })
      messageRegistry.set({ buffer, linter, messages: [messageFirst, messageSecond] })
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(1)
      messageRegistry.deleteByLinter(linter)
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      messageRegistry.update()
      expect(called).toBe(2)
    })
  })
})
