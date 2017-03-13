/* @flow */

import { getConfigFile } from '../helpers'

// Greets
import greetV2Welcome from './greet-v2-welcome'


// Note: This package should not be used from "Main" class,
// Instead it should be used from the main package entry point directly
export default class Greeter {
  notifications: Set<Object>;
  constructor() {
    this.notifications = new Set()
  }
  async activate() {
    let updated = false
    const configFile = await getConfigFile()
    const shown = await configFile.get('greeter.shown')

    if (!shown.includes('V2_WELCOME_MESSAGE')) {
      updated = true
      shown.push('V2_WELCOME_MESSAGE')
      greetV2Welcome()
    }

    if (updated) {
      await configFile.set('greeter.shown', shown)
    }
  }
  dispose() {
    this.notifications.forEach(n => n.dismiss())
    this.notifications.clear()
  }
}
