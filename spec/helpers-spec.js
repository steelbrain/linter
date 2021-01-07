/* @flow */

import fs from 'fs-plus'
import { it } from 'jasmine-fix'
import * as path from 'path'
import * as temp from 'temp'

import * as Helpers from '../dist/helpers'
import { getMessage } from './common'

describe('Helpers', function () {
  // NOTE: Did *not* add specs for messageKey and messageKeyLegacy on purpose
  describe('shouldTriggerLinter', function () {
    function shouldTriggerLinter(a: any, b: any, c: any) {
      return Helpers.shouldTriggerLinter(a, b, c)
    }

    it('works does not trigger non-fly ones on fly', function () {
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
    it('triggers on fly ones on fly', function () {
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
    it('triggers all on non-fly', function () {
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
    it('does not trigger if grammarScopes does not match', function () {
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
  describe('isPathIgnored: ignoredGlob', function () {
    function isPathIgnored(a: any, b: any, c: any) {
      return Helpers.isPathIgnored(a, b || '**/*.min.{js,css}', c || false)
    }

    it('returns false if path does not match glob', async function () {
      expect(await isPathIgnored('a.js')).toBe(false)
      expect(await isPathIgnored('a.css')).toBe(false)
      expect(await isPathIgnored('/a.js')).toBe(false)
      expect(await isPathIgnored('/a.css')).toBe(false)
    })
    it('returns false correctly for windows styled paths', async function () {
      expect(await isPathIgnored('a.js')).toBe(false)
      expect(await isPathIgnored('a.css')).toBe(false)
      expect(await isPathIgnored('\\a.js')).toBe(false)
      expect(await isPathIgnored('\\a.css')).toBe(false)
    })
    it('returns true if path matches glob', async function () {
      expect(await isPathIgnored('a.min.js')).toBe(true)
      expect(await isPathIgnored('a.min.css')).toBe(true)
      expect(await isPathIgnored('/a.min.js')).toBe(true)
      expect(await isPathIgnored('/a.min.css')).toBe(true)
    })
    it('returns true correctly for windows styled paths', async function () {
      expect(await isPathIgnored('a.min.js')).toBe(true)
      expect(await isPathIgnored('a.min.css')).toBe(true)
      expect(await isPathIgnored('\\a.min.js')).toBe(true)
      expect(await isPathIgnored('\\a.min.css')).toBe(true)
    })
    it('returns true if no path is given', async function () {
      expect(await isPathIgnored(undefined)).toBe(true)
      expect(await isPathIgnored(null)).toBe(true)
      expect(await isPathIgnored('')).toBe(true)
    })
  })

  describe('isPathIgnored: ignoredVCS', function () {
    function isPathIgnored(a: any, b: any, c: any) {
      return Helpers.isPathIgnored(a, b || '**/*.min.{js,css}', c || true)
    }

    let workingDir
    beforeEach(() => {
      workingDir = temp.mkdirSync('helpers-spec')
      fs.copySync(path.join(__dirname, 'fixtures'), workingDir)
      fs.moveSync(path.join(workingDir, 'git-dir', 'git.git'), path.join(workingDir, 'git-dir', '.git'))

      waitsForPromise(() => atom.workspace.open(path.join(workingDir, 'git-dir', 'file.txt')))
    })

    it('returns true if the path is ignored by VCS', async () => {
      atom.project.setPaths([path.join(workingDir, 'git-dir')])
      expect(await isPathIgnored(path.join(workingDir, 'git-dir', 'ignore.txt'))).toBe(true)
    })
    it('returns false if the path is not ignored by VCS', async () => {
      atom.project.setPaths([path.join(workingDir, 'git-dir')])
      expect(await isPathIgnored(path.join(workingDir, 'git-dir', 'file.txt'))).toBe(false)
    })
    it('returns true if the path is ignored by VCS with the git directory in a subfolder', async () => {
      atom.project.setPaths([workingDir])
      expect(await isPathIgnored(path.join(workingDir, 'git-dir', 'ignore.txt'))).toBe(true)
    })
    it('returns false if the path is not ignored by VCS with the git directory in a subfolder', async () => {
      atom.project.setPaths([workingDir])
      expect(await isPathIgnored(path.join(workingDir, 'git-dir', 'file.txt'))).toBe(false)
    })
  })

  describe('normalizeMessages', function () {
    it('adds a key to the message', function () {
      const message = getMessage(false)
      expect(typeof message.key).toBe('undefined')
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.key).toBe('string')
    })
    it('adds a version to the message', function () {
      const message = getMessage(false)
      expect(typeof message.version).toBe('undefined')
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.version).toBe('number')
      expect(message.version).toBe(2)
    })
    it('adds a name to the message', function () {
      const message = getMessage(false)
      expect(typeof message.linterName).toBe('undefined')
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.linterName).toBe('string')
      expect(message.linterName).toBe('Some Linter')
    })
    it('preserves linterName if provided', function () {
      const message = getMessage(false)
      message.linterName = 'Some Linter 2'
      Helpers.normalizeMessages('Some Linter', [message])
      expect(typeof message.linterName).toBe('string')
      expect(message.linterName).toBe('Some Linter 2')
    })
    it('converts arrays in location->position to ranges', function () {
      const message = getMessage(false)
      message.location.position = [
        [0, 0],
        [0, 0],
      ]
      expect(Array.isArray(message.location.position)).toBe(true)
      Helpers.normalizeMessages('Some Linter', [message])
      expect(Array.isArray(message.location.position)).toBe(false)
      expect(message.location.position.constructor.name).toBe('Range')
    })
    it('converts arrays in source->position to points', function () {
      const message = getMessage(false)
      message.reference = { file: __dirname, position: [0, 0] }
      expect(Array.isArray(message.reference.position)).toBe(true)
      Helpers.normalizeMessages('Some Linter', [message])
      expect(Array.isArray(message.reference.position)).toBe(false)
      expect(message.reference.position.constructor.name).toBe('Point')
    })
    it('converts arrays in solution[index]->position to ranges', function () {
      const message = getMessage(false)
      message.solutions = [
        {
          position: [
            [0, 0],
            [0, 0],
          ],
          apply() {},
        },
      ]
      expect(Array.isArray(message.solutions[0].position)).toBe(true)
      Helpers.normalizeMessages('Some Linter', [message])
      expect(Array.isArray(message.solutions[0].position)).toBe(false)
      expect(message.solutions[0].position.constructor.name).toBe('Range')
    })
  })
})
