/* @flow */

import { Disposable } from 'atom'
import Linter from './main'
import Greeter from './greeter'
import type { UI, Linter as LinterProvider } from './types'

let greeter
let instance

export default {
  activate() {
    greeter = new Greeter()

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
    }

    instance = new Linter()
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
