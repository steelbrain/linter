'use babel'

/* @flow */

import { CompositeDisposable, Emitter } from 'atom'
import LinterRegistry from './linter-registry'
import IndieLinters from './indie-registry'

type Linter$State = {}

class Linter {
  state: Linter$State;
  subscriptions: CompositeDisposable;
  registryIndie: IndieLinters;
  registryLinters: LinterRegistry;

  constructor(state: Linter$State) {
    this.state = state
    this.subscriptions = new CompositeDisposable()
    this.registryIndie = new IndieLinters()
    this.registryLinters = new LinterRegistry()

    this.subscriptions.add(this.registryIndie)
    this.subscriptions.add(this.registryLinters)
  }
  dispose() {
    this.subscriptions.dispose()
  }
}

module.exports = Linter
