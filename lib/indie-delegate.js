/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'
import type { Message, Indie } from './types'

export default class IndieDelegate {
  name: string;
  scope: 'project';
  emitter: Emitter;
  messages: Map<string, Array<Message>>;
  subscriptions: CompositeDisposable;

  constructor({ name }: Indie) {
    this.name = name
    this.scope = 'project'
    this.emitter = new Emitter()
    this.messages = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }
  getMessages(): Array<Message> {
    return Array.from(this.messages.values()).reduce(function(toReturn, entry) {
      return toReturn.concat(entry)
    }, [])
  }
  clearMessages(): void {
    this.emitter.emit('did-update', [])
    this.messages.clear()
  }
  setMessages(filePath: string, messages: Array<Message>): void {
    this.messages.set(filePath, messages)
    this.emitter.emit('did-update', messages)
  }
  setAllMessages(messages: Array<Message>): void {
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
}
