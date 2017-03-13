/* @flow */

import FS from 'fs'
import { it, wait, beforeEach, afterEach } from 'jasmine-fix'

import ToggleView from '../lib/toggle-view'
import { LINTER_CONFIG_FILE_PATH, getConfigFile } from '../lib/helpers'

describe('Toggle View', function() {
  let oldConfig
  beforeEach(async function() {
    oldConfig = await (await getConfigFile()).get()
  })
  afterEach(async function() {
    await new Promise(resolve => FS.writeFile(LINTER_CONFIG_FILE_PATH, JSON.stringify(oldConfig, null, 2), resolve))
  })

  describe('::getItems', function() {
    it('returns disabled when enabling', async function() {
      const toggleView = new ToggleView('enable', ['Package 1', 'Package 2', 'Package 3'])
      const config = await toggleView.getConfig()
      await config.set('disabled', ['Package 2'])
      expect(await toggleView.getItems()).toEqual(['Package 2'])
    })
    it('returns enabled when disabling', async function() {
      const toggleView = new ToggleView('disable', ['Package 1', 'Package 2', 'Package 3'])
      const config = await toggleView.getConfig()
      await config.set('disabled', ['Package 2'])
      expect(await toggleView.getItems()).toEqual(['Package 1', 'Package 3'])
    })
  })
  it('has a working lifecycle', async function() {
    const didDisable = []
    const toggleView = new ToggleView('disable', ['Package 1', 'Package 2', 'Package 3'])
    const config = await toggleView.getConfig()

    spyOn(toggleView, 'process').andCallThrough()
    spyOn(toggleView, 'getItems').andCallThrough()
    toggleView.onDidDisable(name => didDisable.push(name))

    expect(didDisable).toEqual([])
    expect(toggleView.process.calls.length).toBe(0)
    expect(toggleView.getItems.calls.length).toBe(0)
    expect(atom.workspace.getModalPanels().length).toBe(0)
    await toggleView.show()
    expect(didDisable).toEqual([])
    expect(toggleView.process.calls.length).toBe(0)
    expect(toggleView.getItems.calls.length).toBe(1)
    expect(atom.workspace.getModalPanels().length).toBe(1)

    const element = atom.workspace.getModalPanels()[0].item.element.querySelector('.list-group')
    expect(element.children.length).toBe(3)
    expect(element.children[0].textContent).toBe('Package 1')
    expect(element.children[1].textContent).toBe('Package 2')
    expect(element.children[2].textContent).toBe('Package 3')
    element.children[1].dispatchEvent(new MouseEvent('click'))

    expect(toggleView.process.calls.length).toBe(1)
    expect(toggleView.getItems.calls.length).toBe(1)
    expect(toggleView.process.calls[0].args[0]).toBe('Package 2')
    await wait(50)
    expect(didDisable).toEqual(['Package 2'])
    expect(await config.get('disabled')).toEqual(['Package 2'])
  })
})
