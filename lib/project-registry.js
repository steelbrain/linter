/* @flow */

import chokidar from 'chokidar'
import difference from 'lodash.difference'
import { CompositeDisposable } from 'atom'
import * as Helpers from './helpers'

export default class ProjectRegistry {
  paths: Array<string>;
  queue: Set<string>;
  watcher: Object;
  ignoreVCS: boolean;
  subscriptions: CompositeDisposable;

  constructor() {
    this.paths = []
    this.queue = new Set()
    this.watcher = chokidar.watch([], {
      ignored: path => Helpers.isPathIgnored(path, this.ignoreVCS),
    })
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', (ignoreVCS) => {
      this.ignoreVCS = ignoreVCS
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
  }
  queueFile(path: string) {
    this.queue.add(path)
  }
  clearFile(path: string) {
    this.queue.delete(path)
    // TODO: Remove from existing results, unless editor is open
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
