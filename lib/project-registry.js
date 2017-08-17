/* @flow */

import chokidar from 'chokidar'
import difference from 'lodash.difference'
import { CompositeDisposable, Emitter } from 'atom'
import type { TextEditor } from 'atom'

import * as Helpers from './helpers'

export default class ProjectRegistry {
  paths: Array<string>;
  queue: Array<string>;
  emitter: Emitter;
  editors: Map<string, TextEditor>;
  watcher: Object;
  ignoreVCS: boolean;
  openedEditors: Set<TextEditor>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.paths = []
    this.queue = []
    this.editors = new Map()
    this.emitter = new Emitter()
    this.watcher = chokidar.watch([], {
      ignored: path => Helpers.isPathIgnored(path, this.ignoreVCS),
    })
    this.openedEditors = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', (ignoreVCS) => {
      this.ignoreVCS = ignoreVCS
    }))
    this.subscriptions.add(atom.workspace.observePaneItems((paneItem) => {
      if (!atom.workspace.isTextEditor(paneItem)) return
      this.clearFile(paneItem.getPath())
      this.openedEditors.add(paneItem)
      const subscription = paneItem.onDidDestroy(() => {
        this.subscriptions.delete(subscription)
        this.openedEditors.delete(paneItem)
        this.queueFile(paneItem.getPath())
      })
      this.subscriptions.add(subscription)
    }))
    this.subscriptions.add(atom.project.onDidChangePaths((paths) => {
      const addedPaths = difference(paths, this.paths)
      const removedPaths = difference(this.paths, paths)
      addedPaths.forEach(path => this.startWatching(path))
      removedPaths.forEach(path => this.stopWatching(path))
    }))
    this.watcher.on('add', path => this.queueFile(path))
    this.watcher.on('changed', path => this.queueFile(path))
    this.watcher.on('unlink', path => this.clearFile(path))

    atom.project.getPaths().forEach(path => this.startWatching(path))
    this.processQueue()
  }
  async processQueue(): Promise<void> {
    if (this.subscriptions.disposed) return
    const item = this.queue.shift()
    if (!item) {
      await Helpers.wait(200)
      this.processQueue()
      return
    }
    let headlessEditor = this.editors.get(item)
    if (!headlessEditor) {
      this.editors.set(
        item,
        headlessEditor = await atom.workspace.createItemForURI(item),
      )
    }
    if (headlessEditor) {
      this.emitter.emit('should-lint', headlessEditor)
    }

    await Helpers.wait(100)
    this.processQueue()
  }
  isEditorOpened(path: string): boolean {
    for (const entry of this.openedEditors) {
      if (entry.getPath() === path) return true
    }
    return false
  }
  queueFile(path: string) {
    if (this.isEditorOpened(path) || !path.length) return

    this.queue.push(path)
  }
  clearFile(path: string) {
    if (!path.length) return

    const index = this.queue.indexOf(path)
    if (index !== -1) {
      this.queue.splice(index, 1)
    }
    const editor = this.editors.get(path)
    if (editor) {
      this.emitter.emit('should-clear', editor)
      editor.destroy()
      this.editors.delete(path)
    }
  }
  onShouldLint(callback: ((editor: TextEditor) => void)) {
    return this.emitter.on('should-lint', callback)
  }
  onShouldClear(callback: ((editor: TextEditor) => void)) {
    return this.emitter.on('should-clear', callback)
  }
  startWatching(path: string) {
    this.watcher.add(path)
  }
  stopWatching(path: string) {
    this.watcher.unwatch(path)
  }
  dispose() {
    this.subscriptions.dispose()
    this.paths.forEach(path => this.stopWatching(path))
    this.paths = []
    this.editors.forEach(editor => editor.destroy())
    this.editors.clear()
    this.watcher.close()
  }
}
