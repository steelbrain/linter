/* @flow */

import difference from 'lodash.difference'
import { CompositeDisposable } from 'atom'

export default class ProjectRegistry {
  paths: Array<string>;
  ignoreVCS: boolean;
  subscriptions: CompositeDisposable;

  constructor() {
    this.paths = []
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
    atom.project.getPaths().forEach(path => this.startWatching(path))
  }
  startWatching(path: string) {

  }
  stopWatching(path: string) {

  }
  dispose() {
    this.subscriptions.dispose()
    this.paths.forEach(path => this.stopWatching(path))
    this.paths = []
  }
}
