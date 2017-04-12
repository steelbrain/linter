/* @flow */

import AtomLinter from '../lib/main'
import { getMessage } from './common'

describe('Atom Linter', function() {
  let atomLinter

  beforeEach(function() {
    atomLinter = new AtomLinter()
  })
  afterEach(function() {
    atomLinter.dispose()
  })

  it('feeds old messages to newly added ui providers', function() {
    let patchCalled = 0

    const message = getMessage(true)
    const uiProvider = {
      name: 'test',
      didBeginLinting() {},
      didFinishLinting() {},
      render(patch) {
        expect(patch.added).toEqual([message])
        expect(patch.messages).toEqual([message])
        expect(patch.removed).toEqual([])
        patchCalled++
      },
      dispose() {},
    }
    // Force the MessageRegistry to initialze, note that this is handled under
    // normal usage!
    atomLinter.registryMessagesInit()
    atomLinter.registryMessages.messages.push(message)
    atomLinter.addUI(uiProvider)
    expect(patchCalled).toBe(1)
  })
})
