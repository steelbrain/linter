'use babel'

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
      activate: jasmine.createSpy('ui.activate'),
      didCalculateMessages: jasmine.createSpy('ui.didCalculateMessages'),
      didBeginLinting: jasmine.createSpy('ui.didBeginLinting'),
      didFinishLinting: jasmine.createSpy('ui.didFinishLinting'),
      dispose: jasmine.createSpy('ui.dispose')
    }
  })

  it('works in a lifecycle', function() {
    let testObj

    uiRegistry.add(uiProvider)
    expect(uiProvider.activate).toHaveBeenCalled()

    testObj = {}
    uiRegistry.didCalculateMessages(testObj)
    expect(uiProvider.didCalculateMessages).toHaveBeenCalledWith(testObj)

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
