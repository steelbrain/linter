'use babel'

/* @flow */

import { Point } from 'atom'
import { getMessage } from './common'
import * as Helpers from '../lib/helpers'

describe('Helpers', function() {
  describe('showError', function() {
    it('shows notifications properly', function() {
      expect(atom.notifications.getNotifications().length).toBe(0)
      Helpers.showError(new Error('Hello'))
      expect(atom.notifications.getNotifications().length).toBe(1)
      Helpers.showError(new Error('Hello'))
      expect(atom.notifications.getNotifications().length).toBe(2)
    })
  })

  describe('shouldTriggerLinter', function() {
    it('triggers a normal linter only on save', function() {
      const provider = {
        lintOnFly: false,
        grammarScopes: ['source.js']
      }
      expect(Helpers.shouldTriggerLinter(provider, true, ['source.js'])).toBe(false)
      expect(Helpers.shouldTriggerLinter(provider, false, ['source.js'])).toBe(true)
    })
    it('triggers on fly ones in both scenarios', function() {
      const provider = {
        lintOnFly: true,
        grammarScopes: ['source.js']
      }
      expect(Helpers.shouldTriggerLinter(provider, true, ['source.js'])).toBe(true)
      expect(Helpers.shouldTriggerLinter(provider, false, ['source.js'])).toBe(true)
    })
    it('only triggers if scope matches', function() {
      const provider = {
        lintOnFly: false,
        grammarScopes: ['source.js']
      }
      expect(Helpers.shouldTriggerLinter(provider, false, ['source.js'])).toBe(true)
      expect(Helpers.shouldTriggerLinter(provider, false, ['source.php'])).toBe(false)
    })
  })

  describe('messageKey', function() {
    it('works', function() {
      expect(function() {
        Helpers.messageKey(getMessage('Error'))
      }).not.toThrow()
    })
    it('works with mixed arrays and points in ranges', function() {
      expect(function() {
        const message = getMessage('Error')
        message.range = [new Point(1, 0), new Point(1, 1)]
        Helpers.messageKey(message)
      }).not.toThrow()
    })
  })
})
