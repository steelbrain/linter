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
    this.subscriptions.add(atom.config.observe('linter.displayLinterInfo', displayInfo => {
      this.displayInfo = displayInfo
      this.visibility = typeof this.visibility === 'undefined' ? true : this.visibility
    }))
    this.subscriptions.add(atom.config.observe('linter.statusIconScope', iconScope => {
      this.iconScope = iconScope
      this.status.count = this.tabs.get(iconScope).count
    }))
    this.subscriptions.add(atom.config.observe('linter.displayLinterStatus', visibiltiy => {
      this.status.visibility = visibiltiy
    }))

    for (let tab of this.tabs) {
      this.appendChild(tab[1])
      this.subscriptions.add(tab[1])
    }
    this.appendChild(this.status)

    this.onDidChangeTab(activeName => {
      this.activeTab = activeName
    })
  }
  getTab(name) {
    return this.tabs.get(name)
  }
  setCount({Project, File, Line}) {
    this.tabs.get('Project').count = Project
    this.tabs.get('File').count = File
    this.tabs.get('Line').count = Line
    this.status.count = this.tabs.get(this.iconScope).count
  }

  set activeTab(activeName) {
    this._activeTab = activeName
    for (let [name, tab] of this.tabs) {
      tab.active = name === activeName
    }
  }
  get activeTab() {
    return this._activeTab
  }

  get visibility() {
    return !this.hasAttribute('hidden')
  }
  set visibility(value) {
    if (value && this.displayInfo) {
      this.removeAttribute('hidden')
    } else {
      this.setAttribute('hidden', true)
    }
  }

  onDidChangeTab(callback) {
    const disposable = new CompositeDisposable
    this.tabs.forEach(function(tab) {
      disposable.add(tab.onDidChangeTab(callback))
    })
    return disposable
  }
  onShouldTogglePanel(callback) {
    const disposable = new CompositeDisposable
    this.tabs.forEach(function(tab) {
      disposable.add(tab.onShouldTogglePanel(callback))
    })
    return disposable
  }

  dispose() {
    this.subscriptions.dispose()
    this.tabs.clear()
    this.status = null
  }

  static create(activeTab) {
    const el = document.createElement('linter-bottom-container')
    el.activeTab = activeTab
    return el
  }
}

document.registerElement('linter-bottom-container', {
  prototype: BottomContainer.prototype
})
