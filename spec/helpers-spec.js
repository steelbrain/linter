/* @flow */

import { Disposable } from 'atom'
import { it } from 'jasmine-fix'
import * as Helpers from '../lib/helpers'
import { getFixturesPath, getMessage } from './common'

describe('Helpers', function() {
  // NOTE: Did *not* add specs for messageKey and messageKeyLegacy on purpose
  describe('shouldTriggerLinter', function() {
    function shouldTriggerLinter(a: any, b: any, c: any) {
      return Helpers.shouldTriggerLinter(a, b, c)
    }

    it('works does not trigger non-fly ones on fly', function() {
      expect(
        shouldTriggerLinter(
          {
            lintOnFly: false,
            grammarScopes: ['source.js'],
          },
          true,
          ['source.js'],
        ),
      ).toBe(false)
    })
    it('triggers on fly ones on fly', function() {
      expect(
        shouldTriggerLinter(
          {
            lintsOnChange: true,
            grammarScopes: ['source.js', 'source.coffee'],
          },
          true,
          ['source.js', 'source.js.emebdded'],
        ),
      ).toBe(true)
    })
    it('triggers all on non-fly', function() {
      expect(
        shouldTriggerLinter(
          {
            lintOnFly: false,
            grammarScopes: ['source.js'],
          },
          false,
          ['source.js'],
        ),
      ).toBe(true)
      expect(
        shouldTriggerLinter(
          {
            lintOnFly: true,
            grammarScopes: ['source.js'],
          },
          false,
          ['source.js'],
        ),
      ).toBe(true)
    })
    it('does not trigger if grammarScopes does not match', function() {
      expect(
        shouldTriggerLinter(
          {
            lintOnFly: true,
            grammarScopes: ['source.coffee'],
          },
          true,
          ['source.js'],
        ),
      ).toBe(false)
      expect(
        shouldTriggerLinter(
          {
            lintOnFly: true,
            grammarScopes: ['source.coffee', 'source.go'],
          },
          false,
          ['source.js'],
        ),
      ).toBe(false)
      expect(
        shouldTriggerLinter(
          {
            lintOnFly: false,
            grammarScopes: ['source.coffee', 'source.rust'],
          },
          false,
          ['source.js', 'source.hell'],
        ),
      ).toBe(false)
    })
  })
  describe('isPathIgnored', function() {
    function isPathIgnored(a: any, b: any, c: any) {
      return Helpers.isPathIgnored(a, b || '**/*.min.{js,css}', c || false)
    }

    it('returns false if path does not match glob', function() {
      expect(isPathIgnored('a.js')).toBe(false)
      expect(isPathIgnored('a.css')).toBe(false)
      expect(isPathIgnored('/a.js')).toBe(false)
      expect(isPathIgnored('/a.css')).toBe(false)
    })
    it('returns false correctly for windows styled paths', function() {
      expect(isPathIgnored('a.js')).toBe(false)
      expect(isPathIgnored('a.css')).toBe(false)
      expect(isPathIgnored('\\a.js')).toBe(false)
      expect(isPathIgnored('\\a.css')).toBe(false)
    })
    it('returns true if path matches glob', function() {
      expect(isPathIgnored('a.min.js')).toBe(true)
      expect(isPathIgnored('a.min.css')).toBe(true)
      expect(isPathIgnored('/a.min.js')).toBe(true)
      expect(isPathIgnored('/a.min.css')).toBe(true)
    })
    it('returns true correctly for windows styled paths', function() {
      expect(isPathIgnored('a.min.js')).toBe(true)
      expect(isPathIgnored('a.min.css')).toBe(true)
      expect(isPathIgnored('\\a.min.js')).toBe(true)
      expect(isPathIgnored('\\a.min.css')).toBe(true)
    })
    it('returns true if the path is ignored by VCS', async function() {
      try {
        await atom.workspace.open(__filename)
        expect(isPathIgnored(getFixturesPath('ignored.txt'), null, true)).toBe(true)
      } finally {
        atom.workspace.destroyActivePane()
      }
    })
    it('returns false if the path is not ignored by VCS', async function() {
      try {
        await atom.workspace.open(__filename)
        expect(isPathIgnored(getFixturesPath('file.txt'), null, true)).toBe(false)
      } finally {
        atom.workspace.destroyActivePane()
      }
    })
    it('returns true if no path is given', function() {
      expect(isPathIgnored(undefined)).toBe(true)
      expect(isPathIgnored(null)).toBe(true)
      expect(isPathIgnored('')).toBe(true)
    })
  })
  describe('subscriptiveObserve', function() {
    it('activates synchronously', function() {
      let activated = false
      Helpers.subscriptiveObserve(
        {
          observe(eventName, callback) {
            activated = true
            expect(eventName).toBe('someEvent')
            expect(typeof callback).toBe('function')
          },
        },
        'someEvent',
        function() {},
      )
      expect(activated).toBe(true)
    })
    it('clears last subscription when value changes', function() {
      let disposed = 0
      let activated = false
      Helpers.subscriptiveObserve(
        {
          observe(eventName, callback) {
            activated = true
            expect(disposed).toBe(0)
            callback()
            expect(disposed).toBe(0)
            callback()
            expect(disposed).toBe(1)
            callback()
            expect(disposed).toBe(2)
          },
        },
        'someEvent',
        function() {
          return new Disposable(function() {
            disposed++
          })
        },
      )
      expect(activated).toBe(true)
    })
    it('clears both subscriptions at the end', function() {
      let disposed = 0
      let observeDisposed = 0
      let activated = false
      const subscription = Helpers.subscriptiveObserve(
        {
          observe(eventName, callback) {
            activated = true
            expect(disposed).toBe(0)
            callback()
            expect(disposed).toBe(0)
            return new Disposable(function() {
              observeDisposed++
            })
          },
        },
        'someEvent',
        function() {
          return new Disposable(function() {
            disposed++
          })
        },
      )
      expect(activated).toBe(true)
      subscription.dispose()
      expect(disposed).toBe(1)
      expect(observeDisposed).toBe(1)
    })
  })
  describe('normalizeMessages', function() {
    it('adds a key to the message', function() {
      const message = getMessage(false)
      expect(typeof message.key).toBe('undefined')
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.key).toBe('string')
    })
    it('adds a version to the message', function() {
      const message = getMessage(false)
      expect(typeof message.version).toBe('undefined')
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.version).toBe('number')
      expect(message.version).toBe(2)
    })
    it('adds a name to the message', function() {
      const message = getMessage(false)
      expect(typeof message.linterName).toBe('undefined')
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.linterName).toBe('string')
      expect(message.linterName).toBe('Some Linter')
    })
    it('preserves linterName if provided', function() {
      const message = getMessage(false)
      message.linterName = 'Some Linter 2'
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.linterName).toBe('string')
      expect(message.linterName).toBe('Some Linter 2')
    })
    it('converts arrays in location->position to ranges', function() {
      const message = getMessage(false)
      message.location.position = [[0, 0], [0, 0]]
      expect(Array.isArray(message.location.position)).toBe(true)
      Helpers.normalizeMessages('Some Linter', [message])
      expect(Array.isArray(message.location.position)).toBe(false)
      expect(message.location.position.constructor.name).toBe('Range')
    })
    it('converts arrays in source->position to points', function() {
      const message = getMessage(false)
      message.reference = { file: __dirname, position: [0, 0] }
      expect(Array.isArray(message.reference.position)).toBe(true)
      Helpers.normalizeMessages('Some Linter', [message])
      expect(Array.isArray(message.reference.position)).toBe(false)
      expect(message.reference.position.constructor.name).toBe('Point')
    })
    it('converts arrays in solution[index]->position to ranges', function() {
      const message = getMessage(false)
      message.solutions = [{ position: [[0, 0], [0, 0]], apply() {} }]
      expect(Array.isArray(message.solutions[0].position)).toBe(true)
      Helpers.normalizeMessages('Some Linter', [message])
      expect(Array.isArray(message.solutions[0].position)).toBe(false)
      expect(message.solutions[0].position.constructor.name).toBe('Range')
    })
  })
})
