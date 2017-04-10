/* @flow */

import Greeter from '../lib/greeter'

describe('Greeter', function() {
  let greeter

  beforeEach(function() {
    greeter = new Greeter()
  })
  afterEach(function() {
    greeter.dispose()
  })

  it('Lifecycle (::activate && ::dispose)', function() {
    expect(atom.notifications.getNotifications().length).toBe(0)
    greeter.showWelcome()
    expect(atom.notifications.getNotifications().length).toBe(1)
  })
})
