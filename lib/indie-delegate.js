/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'

import * as Validate from './validate'
import { $file, normalizeMessages, normalizeMessagesLegacy } from './helpers'
import type { LinterMessage, Indie } from './types'

export default class IndieDelegate {
  indie: Indie;
  scope: 'project';
  emitter: Emitter;
  version: 1 | 2
  messages: Map<?string, Array<LinterMessage>>;
  subscriptions: CompositeDisposable;

  constructor(indie: Indie, version: 1 | 2) {
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
  getMessages(): Array<LinterMessage> {
    return Array.from(this.messages.values()).reduce(function(toReturn, entry) {
      return toReturn.concat(entry)
    }, [])
  }
  deleteMessages(): void {
    if (this.version === 1) {
      this.clearMessages()
    }
    throw new Error('Call to depreciated method deleteMessages(). Use clearMessages() insead')
  }
  clearMessages(): void {
    if (!this.subscriptions.disposed) {
      this.emitter.emit('did-update', [])
      this.messages.clear()
    }
  }
  setMessages(filePathOrMessages: string | Array<Object>, messages: ?Array<Object> = null): void {
    if (this.version === 1) {
      if (!Array.isArray(filePathOrMessages)) {
        throw new Error('Parameter 1 to setMessages() must be Array')
      }
      this.setAllMessages(filePathOrMessages)
    }
    if (typeof filePathOrMessages !== 'string' || !Array.isArray(messages)) {
      throw new Error('Invalid Parameters to setMessages()')
    }
    const filePath = filePathOrMessages

    if (this.subscriptions.disposed || !Validate.messages(this.name, messages)) {
      return
    }

    messages.forEach(function(message) {
      if ($file(message) !== filePath) {
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
    if (!Validate[this.version === 1 ? 'messagesLegacy' : 'messages'](this.name, messages)) {
      return
    }
    if (this.version === 1) {
      normalizeMessagesLegacy(this.name, messages)
    } else {
      normalizeMessages(this.name, messages)
    }
    this.messages.clear()
    for (let i = 0, length = messages.length; i < length; ++i) {
      const message: LinterMessage = messages[i]
      const filePath = $file(message)
      let fileMessages = this.messages.get(filePath)
      if (!fileMessages) {
        this.messages.set(filePath, fileMessages = [])
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
