'use babel'

import {CompositeDisposable, Emitter} from 'atom'
import BottomTab from './bottom-tab'
import BottomStatus from './bottom-status'

export default class BottomContainer extends HTMLElement {
  createdCallback() {
    this.subscriptions = new CompositeDisposable
    this.emitter = new Emitter
    this.tabs = new Map()
    this.tabs.set('Line', BottomTab.create('Line'))
    this.tabs.set('File', BottomTab.create('File'))
    this.tabs.set('Project', BottomTab.create('Project'))
    this.status = new BottomStatus

    this.subscriptions.add(this.emitter)
  }

  dispose() {
    this.subscriptions.dispose()
  }
}

document.registerElement('linter-bottom-container', {
  prototype: BottomContainer.prototype
})
