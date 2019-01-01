/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'

import * as Validate from './validate'
import { normalizeMessages } from './helpers'
import type { Indie, Message } from './types'

export default class IndieDelegate {
  indie: Indie
  scope: 'project'
  emitter: Emitter
  version: 2
  messages: Map<?string, Array<Message>>
  subscriptions: CompositeDisposable

  constructor(indie: Indie, version: 2) {
    this.indie = indie
    this.scope = 'project'
    this.version = version
    this.emitter = new Emitter()
    this.messages = new Map()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }
  get name(): string {
    return this.indie.name
  }
  getMessages(): Array<Message> {
    return Array.from(this.messages.values()).reduce(function(toReturn, entry) {
      return toReturn.concat(entry)
    }, [])
  }
  clearMessages(): void {
    if (!this.subscriptions.disposed) {
      this.emitter.emit('did-update', [])
      this.messages.clear()
    }
  }
  setMessages(filePath: string | Array<Object>, messages: ?Array<Object> = null): void {
    // v2 Support from here on
    if (typeof filePath !== 'string' || !Array.isArray(messages)) {
      throw new Error('Invalid Parameters to setMessages()')
    }
    if (this.subscriptions.disposed || !Validate.messages(this.name, messages)) {
      return
    }
    messages.forEach(function(message) {
      if (message.location.file !== filePath) {
        console.debug('[Linter-UI-Default] Expected File', filePath, 'Message', message)
        throw new Error('message.location.file does not match the given filePath')
      }
    })

    normalizeMessages(this.name, messages)
    this.messages.set(filePath, messages)
    this.emitter.emit('did-update', this.getMessages())
  }
  setAllMessages(messages: Array<Object>): void {
    if (this.subscriptions.disposed) {
      return
    }

    if (atom.inDevMode() || !Array.isArray(messages)) {
      if (!Validate.messages(this.name, messages)) return
    }
    normalizeMessages(this.name, messages)

    this.messages.clear()
    for (let i = 0, { length } = messages; i < length; ++i) {
      const message: Message = messages[i]
      const filePath = message.location.file
      let fileMessages = this.messages.get(filePath)
      if (!fileMessages) {
        this.messages.set(filePath, (fileMessages = []))
      }
      fileMessages.push(message)
    }
    this.emitter.emit('did-update', this.getMessages())
  }
  onDidUpdate(callback: Function): Disposable {
    return this.emitter.on('did-update', callback)
  }
  onDidDestroy(callback: Function): Disposable {
    return this.emitter.on('did-destroy', callback)
  }
  dispose(): void {
    this.emitter.emit('did-destroy')
    this.subscriptions.dispose()
    this.messages.clear()
  }
}
