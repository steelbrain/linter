/* @flow */

import IndieRegistry from '../lib/indie-registry'
import { getMessage } from './common'

describe('IndieRegistry', function() {
  let indieRegistry

  beforeEach(function() {
    indieRegistry = new IndieRegistry()
  })
  afterEach(function() {
    indieRegistry.dispose()
  })

  it('triggers observe with existing and new delegates', function() {
    let observeCalled = 0
    indieRegistry.register({ name: 'Chi' }, 2)
    indieRegistry.observe(function() {
      observeCalled++
    })
    expect(observeCalled).toBe(1)
    indieRegistry.register({ name: 'Ping' }, 2)
    expect(observeCalled).toBe(2)
    indieRegistry.register({ name: 'Pong' }, 2)
    expect(observeCalled).toBe(3)
  })
  it('removes delegates from registry as soon as they are dispose', function() {
    expect(indieRegistry.delegates.size).toBe(0)
    const delegate = indieRegistry.register({ name: 'Chi' }, 2)
    expect(indieRegistry.delegates.size).toBe(1)
    delegate.dispose()
    expect(indieRegistry.delegates.size).toBe(0)
  })
  it('triggers update as delegates are updated', function() {
    let timesUpdated = 0
    indieRegistry.onDidUpdate(function() {
      timesUpdated++
    })
    expect(timesUpdated).toBe(0)
    const delegate = indieRegistry.register({ name: 'Panda' }, 2)
    expect(timesUpdated).toBe(0)
    delegate.setAllMessages([getMessage()])
    expect(timesUpdated).toBe(1)
    delegate.setAllMessages([getMessage()])
    expect(timesUpdated).toBe(2)
    delegate.dispose()
    delegate.setAllMessages([getMessage()])
    expect(timesUpdated).toBe(2)
  })
  it('passes on version correctly to the delegates', function() {
    expect(indieRegistry.register({ name: 'Ola' }, 2).version).toBe(2)
    expect(indieRegistry.register({ name: 'Hello' }, 1).version).toBe(1)
  })
})
