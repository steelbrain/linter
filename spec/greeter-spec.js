/* @flow */

import FS from 'fs'
import { it, beforeEach, afterEach } from 'jasmine-fix'
import Greeter from '../lib/greeter'
import { LINTER_CONFIG_FILE_PATH, getConfigFile } from '../lib/helpers'

describe('Greeter', function() {
  let greeter
  let oldConfig
  let configFile

  beforeEach(async function() {
    configFile = await getConfigFile()
    oldConfig = await configFile.get()
    greeter = new Greeter()
    await new Promise(function(resolve) {
      FS.unlink(LINTER_CONFIG_FILE_PATH, function() { resolve() })
    })
  })
  afterEach(async function() {
    greeter.dispose()
    await new Promise(resolve => FS.writeFile(LINTER_CONFIG_FILE_PATH, JSON.stringify(oldConfig, null, 2), resolve))
  })

  it('Lifecycle (::activate && ::dispose)', async function() {
    expect(atom.notifications.getNotifications().length).toBe(0)
    await greeter.activate()
    expect(atom.notifications.getNotifications().length).toBe(1)
    expect(await configFile.get('greeter.shown')).toEqual(['V2_WELCOME_MESSAGE'])
    await greeter.activate()
    expect(atom.notifications.getNotifications().length).toBe(1)
    expect(await configFile.get('greeter.shown')).toEqual(['V2_WELCOME_MESSAGE'])
  })
})
