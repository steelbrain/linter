/* @flow */

import os from 'os'
import pMap from 'p-map'
import { stat } from 'sb-fs'
import chokidar from 'chokidar'
import difference from 'lodash.difference'
import { CompositeDisposable, Emitter } from 'atom'
import type { TextEditor } from 'atom'

import * as Helpers from './helpers'

export default class ProjectRegistry {
  paths: Array<string>;
  queue: Set<string>;
  emitter: Emitter;
  editors: Map<string, TextEditor>;
  watcher: Object;
  ignoreVCS: boolean;
  openedEditors: Set<TextEditor>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.paths = []
    this.queue = new Set()
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
    this.watcher.on('unlink', path => this.clearFile(path, true))

    atom.project.getPaths().forEach(path => this.startWatching(path))
    this.processQueue()
  }
  async processQueue(): Promise<void> {
    if (this.subscriptions.disposed) return
    if (!this.queue.size) {
      await Helpers.wait(200)
      this.processQueue()
      return
    }
    const queue = Array.from(this.queue)
    this.queue.clear()
    await pMap(queue, async (item) => {
      let headlessEditor = this.editors.get(item)
      if (!headlessEditor) {
        let fileStat
        try {
          fileStat = await stat(item)
        } catch (e) { /* No Op */ }
        if (fileStat && fileStat.size <= (1024 * 1024)) {
          const newEditor = await atom.workspace.createItemForURI(item)
          if (atom.workspace.isTextEditor(newEditor)) {
            headlessEditor = newEditor
          }
        }
        this.editors.set(
          item,
          headlessEditor,
        )
      }
      if (headlessEditor) {
        const options = { waitHandle: null, editor: headlessEditor }
        this.emitter.emit('should-lint', options)
        await options.waitHandle
      }
    }, {
      concurrency: os.cpus().length,
    })

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

    this.queue.add(path)
  }
  clearFile(path: string, clear: boolean = false) {
    if (!path.length) return

    this.queue.delete(path)
    const editor = this.editors.get(path)
    if (editor) {
      if (clear) {
        this.emitter.emit('should-clear', editor)
      }
      editor.destroy()
      this.editors.delete(path)
    }
  }
  onShouldLint(callback: ((options: { waitHandle: any, editor: TextEditor }) => void)) {
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
