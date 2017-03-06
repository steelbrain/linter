/* @flow */

import ConfigFile from 'sb-config-file'
import SelectListView from 'atom-select-list'
import { LINTER_CONFIG_FILE_PATH, LINTER_CONFIG_FILE_DEFAULT } from './helpers'

type ToggleAction = 'enable' | 'disable'

export default class ToggleProviders {
  action: ToggleAction;
  config: ConfigFile;
  providers: Array<string>;

  constructor(action: ToggleAction, providers: Array<string>) {
    this.action = action
    this.config = null
    this.providers = providers
  }
  async getConfig(): Promise<ConfigFile> {
    if (!this.config) {
      this.config = await ConfigFile.get(LINTER_CONFIG_FILE_PATH, LINTER_CONFIG_FILE_DEFAULT, {
        prettyPrint: true,
        createIfNonExistent: false,
      })
    }
    return this.config
  }
  async getItems(): Promise<Array<string>> {
    const disabled = await (await this.getConfig()).get('disabled')
    if (this.action === 'disable') {
      return this.providers.filter(name => disabled.indexOf(name) === -1)
    }
    return disabled
  }
  async process(name: string): Promise<void> {
    const config = await this.getConfig()
    const disabled: Array<string> = await config.get('disabled')
    if (this.action === 'disable') {
      disabled.push(name)
    } else {
      const index = disabled.indexOf(name)
      if (index !== -1) {
        disabled.splice(index, 1)
      }
    }
    await this.config.set('disabled', disabled)
  }
  async show() {
    let panel

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
        panel.hide()
        this.process(item)
      },
      didCancelSelection: () => {
        panel.hide()
      },
    })
    panel = atom.workspace.addModalPanel({ item: selectListView })
    selectListView.focus()
  }
}
