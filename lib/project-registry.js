/* @flow */

import chokidar from 'chokidar'
import difference from 'lodash.difference'
import { CompositeDisposable } from 'atom'
import type { TextEditor } from 'atom'

import * as Helpers from './helpers'

export default class ProjectRegistry {
  paths: Array<string>;
  queue: Array<string>;
  watcher: Object;
  ignoreVCS: boolean;
  openedEditors: Set<TextEditor>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.paths = []
    this.queue = []
    this.watcher = chokidar.watch([], {
      ignored: path => Helpers.isPathIgnored(path, this.ignoreVCS),
    })
    this.openedEditors = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', (ignoreVCS) => {
      this.ignoreVCS = ignoreVCS
    }))
    this.subscriptions.add(atom.workspace.observePaneItems((paneItem) => {
      if (!atom.workspace.isTextEditor(paneItem)) return
      this.openedEditors.add(paneItem)
      const subscription = paneItem.onDidDestroy(() => {
        this.subscriptions.delete(subscription)
        this.openedEditors.delete(paneItem)
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
    console.log('item', item)

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
    if (this.isEditorOpened(path)) return

    this.queue.push(path)
  }
  clearFile(path: string) {
    if (this.isEditorOpened(path)) return

    const index = this.queue.indexOf(path)
    if (index !== -1) {
      this.queue.splice(index, 1)
    }
    // TODO: Remove from existing results
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
    this.watcher.close()
  }
}
