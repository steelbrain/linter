/* @flow */

import UIRegistry from '../lib/ui-registry'

let uiRegistry
let uiProvider: Object

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
    const testObjA: Object = {}
    const testObjB: Object = {}
    const testObjC: Object = {}

    uiRegistry.add(uiProvider)

    uiRegistry.render(testObjA)
    expect(uiProvider.render).toHaveBeenCalledWith(testObjA)

    uiRegistry.didBeginLinting(testObjB)
    expect(uiProvider.didBeginLinting.mostRecentCall.args[0]).toBe(testObjB)
    expect(uiProvider.didBeginLinting.mostRecentCall.args[1]).toBe(null)

    uiRegistry.didFinishLinting(testObjC)
    expect(uiProvider.didFinishLinting.mostRecentCall.args[0]).toBe(testObjC)
    expect(uiProvider.didFinishLinting.mostRecentCall.args[1]).toBe(null)

    uiRegistry.dispose()
    expect(uiProvider.dispose).toHaveBeenCalled()
  })
})
