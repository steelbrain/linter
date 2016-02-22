'use babel'

import Commands from '../lib/commands'
import {join} from 'path'
let commands

describe('Linter Commands', function() {
  beforeEach(function() {
    if (commands) {
      commands.dispose()
    }
    commands = new Commands()
  })
  it('properly notifies its listeners of command execution', function() {

    let lintCalled = 0
    let toggleCalled = 0

    commands.onShouldLint(() => ++lintCalled)
    commands.onShouldToggleActiveEditor(() => ++toggleCalled)

    waitsForPromise(function() {
      return atom.workspace.open(join(__dirname, 'fixtures', 'file.txt'))
        .then(function() {
          const textEditor = atom.views.getView(atom.workspace.getActiveTextEditor())
          atom.commands.dispatch(textEditor, 'linter:lint')
          atom.commands.dispatch(textEditor, 'linter:toggle-active-editor')

          expect(lintCalled).toBe(1)
          expect(toggleCalled).toBe(1)
        })
    })
  })
})
