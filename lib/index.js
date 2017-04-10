/* @flow */

import FS from 'sb-fs'
import Path from 'path'
import { Disposable } from 'atom'

import Linter from './main'
import Greeter from './greeter'
import type { UI, Linter as LinterProvider } from './types'

let greeter
let instance

export default {
  async activate() {
    greeter = new Greeter()
    instance = new Linter()

    const linterConfigs = atom.config.get('linter')
    // Unset v1 configs
    const removedV1Configs = [
      'lintOnFly',
      'lintOnFlyInterval',
      'ignoredMessageTypes',
      'ignoreVCSIgnoredFiles',
      'ignoreMatchedFiles',
      'showErrorInline',
      'inlineTooltipInterval',
      'gutterEnabled',
      'gutterPosition',
      'underlineIssues',
      'showProviderName',
      'showErrorPanel',
      'errorPanelHeight',
      'alwaysTakeMinimumSpace',
      'displayLinterInfo',
      'displayLinterStatus',
      'showErrorTabLine',
      'showErrorTabFile',
      'showErrorTabProject',
      'statusIconScope',
      'statusIconPosition',
    ]
    if (removedV1Configs.some(config => ({}.hasOwnProperty.call(linterConfigs, config)))) {
      greeter.showWelcome()
    }
    removedV1Configs.forEach((e) => { atom.config.unset(`linter.${e}`) })

    if (!atom.inSpecMode()) {
      // eslint-disable-next-line global-require
      require('atom-package-deps').install('linter', true)

      // TODO: Remove this after a few version bumps
      const oldConfigFile = Path.join(atom.getConfigDirPath(), 'linter-config.json')
      if (await FS.exists(oldConfigFile)) {
        let disabledProviders = atom.config.get('linter.disabledProviders')
        try {
          const oldConfigFileContents = await FS.readFile(oldConfigFile, 'utf8')
          disabledProviders = disabledProviders.concat(JSON.parse(oldConfigFileContents).disabled)
        } catch (_) { console.error('[Linter] Error reading old state file', _) }
        atom.config.set('linter.disabledProviders', disabledProviders)
        try {
          await FS.unlink(oldConfigFile)
        } catch (_) { /* No Op */ }
      }
    }
  },
  consumeLinter(linter: LinterProvider): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      instance.addLinter(entry)
    }
    return new Disposable(() => {
      for (const entry of linters) {
        instance.deleteLinter(entry)
      }
    })
  },
  consumeLinterLegacy(linter: LinterProvider): Disposable {
    const linters = [].concat(linter)
    for (const entry of linters) {
      linter.name = linter.name || 'Unknown'
      linter.lintOnFly = Boolean(linter.lintOnFly)
      instance.addLinter(entry, true)
    }
    return new Disposable(() => {
      for (const entry of linters) {
        instance.deleteLinter(entry)
      }
    })
  },
  consumeUI(ui: UI): Disposable {
    const uis = [].concat(ui)
    for (const entry of uis) {
      instance.addUI(entry)
    }
    return new Disposable(() => {
      for (const entry of uis) {
        instance.deleteUI(entry)
      }
    })
  },
  provideIndie(): Object {
    return indie =>
      instance.registryIndie.register(indie, 2)
  },
  provideIndieLegacy(): Object {
    return {
      register: indie => instance.registryIndie.register(indie, 1),
    }
  },
  deactivate() {
    instance.dispose()
    greeter.dispose()
  },
}
