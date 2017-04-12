/* @flow */

import { CompositeDisposable, Disposable } from 'atom'

import Linter from './main'
import type { UI, Linter as LinterProvider } from './types'

// Internal variables
let instance

const idleCallbacks = new Set()

export default {
  activate() {
    this.subscriptions = new CompositeDisposable()

    instance = new Linter()
    this.subscriptions.add(instance)

    // TODO: Remove this after a few version bumps
    const oldConfigCallbackID = window.requestIdleCallback(async function linterOldConfigs() {
      idleCallbacks.delete(oldConfigCallbackID)
      const FS = require('sb-fs')
      const Path = require('path')
      const Greeter = require('./greeter')

      // Greet the user if they are coming from Linter v1
      const greeter = new Greeter()
      this.subscriptions.add(greeter)
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

      // There was an external config file in use briefly, migrate any use of that to settings
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
    }.bind(this))
    idleCallbacks.add(oldConfigCallbackID)

    const linterDepsCallback = window.requestIdleCallback(function linterDepsInstall() {
      idleCallbacks.delete(linterDepsCallback)
      if (!atom.inSpecMode()) {
        // eslint-disable-next-line global-require
        require('atom-package-deps').install('linter', true)
      }
    })
    idleCallbacks.add(linterDepsCallback)
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
      instance.addIndie(indie)
  },
  provideIndieLegacy(): Object {
    return {
      register: indie => instance.addLegacyIndie(indie),
    }
  },
  deactivate() {
    idleCallbacks.forEach(callbackID => window.cancelIdleCallback(callbackID))
    idleCallbacks.clear()
    this.subscriptions.dispose()
  },
}
