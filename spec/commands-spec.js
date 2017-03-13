/* @flow */

import Path from 'path'
import { it } from 'jasmine-fix'
import Commands from '../lib/commands'

let commands

describe('Linter Commands', function() {
  beforeEach(function() {
    if (commands) {
      commands.dispose()
    }
    commands = new Commands()
    // Initial workspace view
    atom.views.getView(atom.workspace)
  })
  it('properly notifies its listeners of command execution', async function() {
    let lintCalled = 0
    let debugCalled = 0
    let toggleActiveCalled = 0
    const toggleLinterCalled = []

    commands.onShouldLint(() => ++lintCalled)
    commands.onShouldToggleActiveEditor(() => ++toggleActiveCalled)
    commands.onShouldDebug(() => ++debugCalled)
    commands.onShouldToggleLinter(type => toggleLinterCalled.push(type))

    await atom.workspace.open(Path.join(__dirname, 'fixtures', 'file.txt'))
    const textEditor = atom.views.getView(atom.workspace.getActiveTextEditor())

    expect(lintCalled).toBe(0)
    expect(debugCalled).toBe(0)
    expect(toggleActiveCalled).toBe(0)
    expect(toggleLinterCalled).toEqual([])
    atom.commands.dispatch(textEditor, 'linter:lint')
    expect(lintCalled).toBe(1)
    expect(debugCalled).toBe(0)
    expect(toggleActiveCalled).toBe(0)
    expect(toggleLinterCalled).toEqual([])
    atom.commands.dispatch(textEditor, 'linter:toggle-active-editor')
    expect(lintCalled).toBe(1)
    expect(toggleActiveCalled).toBe(1)
    expect(debugCalled).toBe(0)
    expect(toggleLinterCalled).toEqual([])
    atom.commands.dispatch(textEditor, 'linter:debug')
    expect(lintCalled).toBe(1)
    expect(debugCalled).toBe(1)
    expect(toggleActiveCalled).toBe(1)
    expect(toggleLinterCalled).toEqual([])
    atom.commands.dispatch(textEditor, 'linter:enable-linter')
    expect(lintCalled).toBe(1)
    expect(debugCalled).toBe(1)
    expect(toggleActiveCalled).toBe(1)
    expect(toggleLinterCalled).toEqual(['enable'])
    atom.commands.dispatch(textEditor, 'linter:disable-linter')
    expect(lintCalled).toBe(1)
    expect(debugCalled).toBe(1)
    expect(toggleActiveCalled).toBe(1)
    expect(toggleLinterCalled).toEqual(['enable', 'disable'])
  })
})
