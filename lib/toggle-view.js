/* @flow */

import SelectListView from 'atom-select-list'
import { CompositeDisposable, Emitter, Disposable } from 'atom'

type ToggleAction = 'enable' | 'disable'

class ToggleProviders {
  action: ToggleAction;
  emitter: Emitter;
  providers: Array<string>;
  subscriptions: CompositeDisposable;
  disabledProviders: Array<string>;

  constructor(action: ToggleAction, providers: Array<string>) {
    this.action = action
    this.emitter = new Emitter()
    this.providers = providers
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
    this.subscriptions.add(atom.config.observe('linter.disabledProviders', (disabledProviders) => {
      this.disabledProviders = disabledProviders
    }))
  }
  async getItems(): Promise<Array<string>> {
    if (this.action === 'disable') {
      return this.providers.filter(name => !this.disabledProviders.includes(name))
    }
    return this.disabledProviders
  }
  async process(name: string): Promise<void> {
    if (this.action === 'disable') {
      this.disabledProviders.push(name)
      this.emitter.emit('did-disable', name)
    } else {
      const index = this.disabledProviders.indexOf(name)
      if (index !== -1) {
        this.disabledProviders.splice(index, 1)
      }
    }
    atom.config.set('linter.disabledProviders', this.disabledProviders)
  }
  async show() {
    const selectListView = new SelectListView({
      items: await this.getItems(),
      emptyMessage: 'No matches found',
      filterKeyForItem: item => item,
      elementForItem: (item) => {
        const li = document.createElement('li')
        li.textContent = item
        return li
      },
      didConfirmSelection: (item) => {
        this.process(item).catch(e => console.error('[Linter] Unable to process toggle:', e)).then(() => this.dispose())
      },
      didCancelSelection: () => {
        this.dispose()
      },
    })
    const panel = atom.workspace.addModalPanel({ item: selectListView })

    selectListView.focus()
    this.subscriptions.add(new Disposable(function() {
      panel.destroy()
    }))
  }
  onDidDispose(callback: (() => any)): Disposable {
    return this.emitter.on('did-dispose', callback)
  }
  onDidDisable(callback: ((name: string) => any)): Disposable {
    return this.emitter.on('did-disable', callback)
  }
  dispose() {
    this.emitter.emit('did-dispose')
    this.subscriptions.dispose()
  }
}

module.exports = ToggleProviders
