/* @flow */

import UIRegistry from '../lib/ui-registry'
let uiRegistry = null
let uiProvider = null

describe('UI Registry', function() {
  beforeEach(function() {
    if (uiRegistry) {
      uiRegistry.dispose()
    }
    uiRegistry = new UIRegistry()
    uiProvider = {
      name: 'Test',
      render: jasmine.createSpy('ui.didCalculateMessages'),
      didBeginLinting: jasmine.createSpy('ui.didBeginLinting'),
      didFinishLinting: jasmine.createSpy('ui.didFinishLinting'),
      dispose: jasmine.createSpy('ui.dispose'),
    }
  })

  it('works in a lifecycle', function() {
    let testObj

    uiRegistry.add(uiProvider)

    testObj = {}
    uiRegistry.render(testObj)
    expect(uiProvider.render).toHaveBeenCalledWith(testObj)

    testObj = {}
    uiRegistry.didBeginLinting(testObj)
    expect(uiProvider.didBeginLinting.mostRecentCall.args[0]).toBe(testObj)
    expect(uiProvider.didBeginLinting.mostRecentCall.args[1]).toBe(null)

    testObj = {}
    uiRegistry.didFinishLinting(testObj)
    expect(uiProvider.didFinishLinting.mostRecentCall.args[0]).toBe(testObj)
    expect(uiProvider.didFinishLinting.mostRecentCall.args[1]).toBe(null)

    uiRegistry.dispose()
    expect(uiProvider.dispose).toHaveBeenCalled()
  })
})
