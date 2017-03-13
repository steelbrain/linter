/* @flow */

import ConfigFile from 'sb-config-file'
import SelectListView from 'atom-select-list'
import { CompositeDisposable, Emitter, Disposable } from 'atom'
import { getConfigFile } from './helpers'

type ToggleAction = 'enable' | 'disable'

export default class ToggleProviders {
  action: ToggleAction;
  config: ConfigFile;
  emitter: Emitter;
  providers: Array<string>;
  subscriptions: CompositeDisposable;

  constructor(action: ToggleAction, providers: Array<string>) {
    this.action = action
    this.config = null
    this.emitter = new Emitter()
    this.providers = providers
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }
  async getConfig(): Promise<ConfigFile> {
    if (!this.config) {
      this.config = await getConfigFile()
    }
    return this.config
  }
  async getItems(): Promise<Array<string>> {
    const disabled = await (await this.getConfig()).get('disabled')
    if (this.action === 'disable') {
      return this.providers.filter(name => !disabled.includes(name))
    }
    return disabled
  }
  async process(name: string): Promise<void> {
    const config = await this.getConfig()
    const disabled: Array<string> = await config.get('disabled')
    if (this.action === 'disable') {
      disabled.push(name)
      this.emitter.emit('did-disable', name)
    } else {
      const index = disabled.indexOf(name)
      if (index !== -1) {
        disabled.splice(index, 1)
      }
    }
    await this.config.set('disabled', disabled)
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
