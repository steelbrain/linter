/* @flow */

import MessageRegistry from '../dist/message-registry'
import { getMessage } from './common'
import { normalizeMessages } from '../dist/helpers'

describe('Message Registry', function () {
  let messageRegistry
  beforeEach(function () {
    messageRegistry = new MessageRegistry()
    messageRegistry.debouncedUpdate = jasmine.createSpy('debouncedUpdate')

    // object compare
    this.addMatchers({
      toInclude(expected) {
        let failed: any
        for (const i in expected) {
          /* eslint-disable no-prototype-builtins */
          if (expected.hasOwnProperty(i) && !this.actual.hasOwnProperty(i)) {
            failed = [i, expected[i]]
            break
          }
        }
        if (undefined !== failed) {
          this.message = function () {
            return `Failed asserting that array includes element "${failed[0]} => ${failed[1]}"`
          }
          return false
        }

        return true
      },
    })
  })
  afterEach(function () {
    messageRegistry.dispose()
  })

  describe('::set', function () {
    it('stores results using both buffer and linter', function () {
      const messageFirst = getMessage()
      const messageSecond = getMessage()
      const messageThird = getMessage()
      const linter: Object = { name: 'any' }
      const buffer: Object = {}
      let info

      messageRegistry.set({ linter, buffer: null, messages: [messageFirst] })
      // $FlowIgnore: Jasmine spy'ed function
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(1)
      expect(messageRegistry.messagesMap.size).toBe(1)
      ;[info] = Array.from(messageRegistry.messagesMap)

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.oldMessages.length).toBe(0)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      messageRegistry.set({ linter, buffer: null, messages: [messageFirst] })
      // $FlowIgnore: Jasmine spy'ed function
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(2)
      expect(messageRegistry.messagesMap.size).toBe(1)
      ;[info] = Array.from(messageRegistry.messagesMap)

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)

      messageRegistry.set({ linter, buffer, messages: [messageThird] })
      // $FlowIgnore: Jasmine spy'ed function
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(3)
      expect(messageRegistry.messagesMap.size).toBe(2)
      ;[info] = Array.from(messageRegistry.messagesMap)

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageFirst)
      ;[, info] = Array.from(messageRegistry.messagesMap)

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(buffer)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageThird)

      messageRegistry.set({ linter, buffer: null, messages: [messageFirst, messageSecond] })
      // $FlowIgnore: Jasmine spy'ed function
      expect(messageRegistry.debouncedUpdate.calls.length).toBe(4)
      expect(messageRegistry.messagesMap.size).toBe(2)
      ;[info] = Array.from(messageRegistry.messagesMap)

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(null)
      expect(info.messages.length).toBe(2)
      expect(info.messages[0]).toBe(messageFirst)
      expect(info.messages[1]).toBe(messageSecond)
      ;[, info] = Array.from(messageRegistry.messagesMap)

      expect(info.changed).toBe(true)
      expect(info.linter).toBe(linter)
      expect(info.buffer).toBe(buffer)
      expect(info.messages.length).toBe(1)
      expect(info.messages[0]).toBe(messageThird)
    })
  })

  describe('updates (::update & ::onDidUpdateMessages)', function () {
    it('notifies on changes', function () {
      let called = 0
      const linter: Object = { name: 'any' }
      const message = getMessage()
      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
        called++
        expect(added.length).toBe(1)
        expect(removed.length).toBe(0)
        expect(messages.length).toBe(1)
        expect(added).toEqual(messages)
        expect(added[0]).toBe(message)
      })
      messageRegistry.set({ linter, buffer: null, messages: [message] })
      messageRegistry.update()
      expect(called).toBe(1)
    })
    it('notifies properly for as many linters as you want', function () {
      const buffer: Object = {}
      const linterFirst: Object = { name: 'any' }
      const linterSecond: Object = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()
      const messageThird = getMessage()
      let called = 0

      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
        called++

        if (called === 1) {
          expect(added.length).toBe(1)
          expect(removed.length).toBe(0)
          expect(added).toEqual(messages)
          expect(added[0]).toEqual(messageFirst)
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

    it('sets key, severity on messages', function () {
      const linter: Object = { name: 'any' }
      const buffer: Object = {}
      const messageFirst = getMessage(true)
      const messageSecond = getMessage(true)
      const messageThird = getMessage(true)

      let called = 0

      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
        called++
        if (called === 1) {
          // All messages are new
          expect(added.length).toBe(2)
          expect(removed.length).toBe(0)
          expect(messages.length).toBe(2)
          expect(added).toEqual(messages)
          expect(typeof messages[0].key).toBe('string')
          expect(typeof messages[1].key).toBe('string')
          expect(typeof messages[0].severity).toBe('string')
          expect(typeof messages[1].severity).toBe('string')
        } else {
          // One removed, one added
          expect(added.length).toBe(1)
          expect(removed.length).toBe(1)
          expect(messages.length).toBe(2)
          expect(messages.indexOf(added[0])).not.toBe(-1)
          expect(typeof messages[0].key).toBe('string')
          expect(typeof messages[1].key).toBe('string')
          expect(typeof messages[0].severity).toBe('string')
          expect(typeof messages[1].severity).toBe('string')
        }
      })

      messageRegistry.set({ buffer, linter, messages: [messageFirst, messageSecond] })
      messageRegistry.update()
      messageRegistry.set({ buffer, linter, messages: [messageFirst, messageThird] })
      messageRegistry.update()
      expect(called).toBe(2)
    })

    // this test was changed in https://github.com/steelbrain/linter/pull/1706
    it('does not perform redundant updates if the message is the same', function () {
      let called = 0
      const messageFirst = getMessage(true)
      const messageSecond = { ...messageFirst }
      const linter: Object = { name: 'any' }
      const buffer: Object = {}

      const messageSecondChanged = Object.assign({}, messageSecond)
      messageSecondChanged.excerpt = 'Hellow'
      console.log({ messageFirst, messageSecondChanged })
      normalizeMessages('Some Linter', [messageSecondChanged])

      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
        called++
        if (called === 1) {
          expect(messages.length).toBe(1)
          expect(removed.length).toBe(0)
          expect(added.length).toBe(1)
          expect(added[0]).toBe(messageFirst)
        } else {
          expect(messages.length).toBe(1)
          expect(removed.length).toBe(1)
          expect(added.length).toBe(1)
          expect(added[0]).toInclude(messageSecondChanged)
          expect(removed[0]).toBe(messageSecond)
        }
      })

      expect(called).toBe(0)
      messageRegistry.set({ buffer, linter, messages: [messageFirst] })
      messageRegistry.update()
      expect(called).toBe(1)
      messageRegistry.set({ buffer, linter, messages: [messageSecond] })
      messageRegistry.update()
      expect(called).toBe(1) // messageSecond has the same properties as messageFirst, so update is not called
      // cloning a changed messageSecond
      messageRegistry.set({ buffer, linter, messages: [messageSecondChanged] })
      messageRegistry.update()
      expect(called).toBe(2)
    })

    it('sends the same object each time even in complicated scenarios', function () {
      let called = 0
      const knownMessages = new Map()
      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
        called++
        for (const entry of added) {
          if (knownMessages.has(entry)) {
            throw new Error('Message already exists')
          } else {
            knownMessages.set(entry.key, entry)
          }
        }
        for (const entry of removed) {
          if (knownMessages.has(entry.key)) {
            knownMessages.delete(entry.key)
          } else {
            throw new Error('Message does not exist')
          }
        }
        if (messages.length !== knownMessages.size) {
          throw new Error('Size mismatch, registry is having hiccups')
        }
      })

      const linter: Object = { name: 'any' }
      const buffer: Object = {}
      const messageRealFirst = getMessage(true)
      const messageDupeFirst = Object.assign({}, messageRealFirst)
      const messageRealSecond = getMessage(true)
      const messageDupeSecond = Object.assign({}, messageRealSecond)

      expect(called).toBe(0)
      messageRegistry.set({ buffer, linter, messages: [messageRealFirst, messageRealSecond] })
      messageRegistry.update()
      expect(called).toBe(1)
      expect(knownMessages.size).toBe(2)
      messageRegistry.update()
      expect(called).toBe(1)
      expect(knownMessages.size).toBe(2)
      messageRegistry.set({ buffer, linter, messages: [messageRealFirst, messageRealSecond] })
      messageRegistry.update()
      expect(called).toBe(1)
      expect(knownMessages.size).toBe(2)
      messageRegistry.set({ buffer, linter, messages: [messageDupeFirst, messageDupeSecond] })
      messageRegistry.update()
      expect(called).toBe(1)
      expect(knownMessages.size).toBe(2)
      messageRegistry.deleteByLinter(linter)
      messageRegistry.update()
      expect(called).toBe(2)
      expect(knownMessages.size).toBe(0)
    })

    // This functionality was removed in https://github.com/steelbrain/linter/pull/1706 due to performance reasons
    //   it('notices changes on last messages instead of relying on their keys and invalidates them', function() {
    //     let called = 0
    //
    //     const linter: Object = { name: 'any' }
    //     const buffer: Object = {}
    //     const messageA = getMessage(true)
    //     const messageB = Object.assign({}, messageA)
    //     const messageC = Object.assign({}, messageA)
    //
    //     messageRegistry.onDidUpdateMessages(function({ added, removed, messages }) {
    //       called++
    //       if (called === 1) {
    //         expect(added.length).toBe(1)
    //         expect(removed.length).toBe(0)
    //         expect(messages.length).toBe(1)
    //         expect(added).toEqual(messages)
    //         expect(added[0]).toBe(messageA)
    //       } else if (called === 2) {
    //         expect(added.length).toBe(1)
    //         expect(removed.length).toBe(1)
    //         expect(messages.length).toBe(1)
    //         expect(added).toEqual(messages)
    //         expect(added[0]).toBe(messageB)
    //         expect(removed[0]).toBe(messageA)
    //       } else {
    //         throw new Error('Should not have been triggered')
    //       }
    //     })
    //     messageRegistry.set({ buffer, linter, messages: [messageA] })
    //     messageRegistry.update()
    //     messageA.excerpt = 'MURICAAA'
    //     messageRegistry.set({ buffer, linter, messages: [messageB] })
    //     messageRegistry.update()
    //     messageRegistry.set({ buffer, linter, messages: [messageC] })
    //     messageRegistry.update()
    //     expect(called).toBe(2)
    //   })
  })

  describe('::deleteByBuffer', function () {
    it('deletes the messages and sends them in an event', function () {
      const linter: Object = { name: 'any' }
      const buffer: Object = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()

      let called = 0

      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
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

  describe('::deleteByLinter', function () {
    it('deletes the messages and sends them in an event', function () {
      const linter: Object = { name: 'any' }
      const buffer: Object = {}
      const messageFirst = getMessage()
      const messageSecond = getMessage()

      let called = 0

      messageRegistry.onDidUpdateMessages(function ({ added, removed, messages }) {
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
