'use babel'

import {CompositeDisposable} from 'atom'
import BottomPanelElement from './bottom-panel-element'

export class BottomPanel {
  constructor() {
    this.subscriptions = new CompositeDisposable
    this.element = new BottomPanelElement()
    this.panel = atom.workspace.addBottomPanel({item: this.element, visible: false, priority: 500})
    this.visibility = false

    this.subscriptions.add(atom.config.observe('linter.showErrorPanel', value => {
      this.configVisibility = value
    }))
  }
  getVisibility() {
    return this.visibility
  }
  setVisibility(value){
    if (value && this.configVisibility) {
      this.panel.show()
    } else {
      this.panel.hide()
    }
    this.visibility = value
  }
  dispose() {
    this.subscriptions.dispose()
    this.panel.destroy()
  }
}
