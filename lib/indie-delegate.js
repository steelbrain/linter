/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'

import { normalizeMessages } from './helpers'
import { messages as validateMessages } from './validate'
import type { Message, Indie } from './types'

export default class IndieDelegate {
  indie: Indie;
  scope: 'project';
  emitter: Emitter;
  messages: Map<string, Array<Message>>;
  subscriptions: CompositeDisposable;

  constructor(indie: Indie) {
    this.indie = indie
    this.scope = 'project'
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
  setMessages(filePath: string, messages: Array<Message>): void {
    if (this.subscriptions.disposed || !IndieDelegate.normalizeMessages(this.name, messages)) {
      return
    }

    for (let i = 0, length = messages.length; i < length; ++i) {
      if (messages[i].location.file !== filePath) {
        throw new Error(`messages[${i}].location.file does not match the given filePath`)
      }
    }

    normalizeMessages(this.name, messages)
    this.messages.set(filePath, messages)
    this.emitter.emit('did-update', messages)
  }
  setAllMessages(messages: Array<Message>): void {
    if (this.subscriptions.disposed || !IndieDelegate.normalizeMessages(this.name, messages)) {
      return
    }
    this.messages.clear()
    for (let i = 0, length = messages.length; i < length; ++i) {
      const message: Message = messages[i]
      const filePath = message.location.file
      let fileMessages = this.messages.get(filePath)
      if (!fileMessages) {
        this.messages.set(filePath, fileMessages = [])
      }
      fileMessages.push(message)
    }
    this.emitter.emit('did-update', messages)
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
  static normalizeMessages(name: string, messages: Array<Message>): boolean {
    let validity = true
    if (atom.inDevMode()) {
      validity = validateMessages(this.name, messages)
    }
    if (validity) {
      normalizeMessages(this.name, messages)
    }
    return validity
  }
}
