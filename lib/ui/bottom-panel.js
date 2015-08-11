'use babel'

import {CompositeDisposable} from 'atom'
import {BottomPanelElement} from './bottom-panel-element'

export class BottomPanel {
  constructor() {
    this.subscriptions = new CompositeDisposable
    this.element = new BottomPanelElement()

    this.subscriptions.add(atom.config.observe('linter.showErrorPanel', value => {
      this.configVisibility = value
    }))
  }
  dispose() {
    this.subscriptions.dispose()
  }
}
